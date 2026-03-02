package com.ljwx.platform.app.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ljwx.platform.app.dto.WebhookConfigDTO;
import com.ljwx.platform.app.dto.WebhookConfigQueryDTO;
import com.ljwx.platform.app.dto.WebhookLogQueryDTO;
import com.ljwx.platform.app.infra.mapper.WebhookConfigMapper;
import com.ljwx.platform.app.infra.mapper.WebhookLogMapper;
import com.ljwx.platform.app.vo.WebhookConfigVO;
import com.ljwx.platform.app.vo.WebhookLogVO;
import com.ljwx.platform.app.domain.entity.WebhookConfig;
import com.ljwx.platform.app.domain.entity.WebhookLog;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.Base64;
import java.util.List;
import java.util.Map;

/**
 * Webhook Service
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WebhookService {

    private final WebhookConfigMapper webhookConfigMapper;
    private final WebhookLogMapper webhookLogMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final ObjectMapper objectMapper;

    private static final String STATUS_ENABLED = "ENABLED";
    private static final String STATUS_SUCCESS = "SUCCESS";
    private static final String STATUS_FAILURE = "FAILURE";

    /**
     * Create webhook config
     *
     * @param dto webhook config DTO
     * @return webhook config ID
     */
    @Transactional
    public Long createWebhookConfig(WebhookConfigDTO dto) {
        WebhookConfig config = new WebhookConfig();
        config.setId(idGenerator.nextId());
        config.setWebhookName(dto.getWebhookName());
        config.setWebhookUrl(dto.getWebhookUrl());

        try {
            config.setEventTypes(objectMapper.writeValueAsString(dto.getEventTypes()));
        } catch (JsonProcessingException e) {
            throw new BusinessException(ErrorCode.INTERNAL_ERROR, "事件类型序列化失败");
        }

        config.setSecretKey(dto.getSecretKey());
        config.setStatus(dto.getStatus());
        config.setRetryCount(dto.getRetryCount() != null ? dto.getRetryCount() : 5);
        config.setTimeoutSeconds(dto.getTimeoutSeconds() != null ? dto.getTimeoutSeconds() : 5);

        webhookConfigMapper.updateById(config);
    }

    /**
     * Delete webhook config
     *
     * @param id webhook config ID
     */
    @Transactional
    public void deleteWebhookConfig(Long id) {
        WebhookConfig config = webhookConfigMapper.selectById(id);
        if (config == null || config.getDeleted()) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Webhook 配置不存在");
        }

        config.setDeleted(true);
        webhookConfigMapper.updateById(config);
    }

    /**
     * Get webhook config by ID
     *
     * @param id webhook config ID
     * @return webhook config VO
     */
    public WebhookConfigVO getWebhookConfigById(Long id) {
        WebhookConfigVO vo = webhookConfigMapper.selectWebhookConfigById(id);
        if (vo == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Webhook 配置不存在");
        }
        return vo;
    }

    /**
     * List webhook configs
     *
     * @param query query conditions
     * @return page result
     */
    public PageResult<WebhookConfigVO> listWebhookConfigs(WebhookConfigQueryDTO query) {
        List<WebhookConfigVO> list = webhookConfigMapper.selectWebhookConfigList(query);
        long total = webhookConfigMapper.countWebhookConfigs(query);
        return new PageResult<>(list, total);
    }

    /**
     * List webhook logs
     *
     * @param query query conditions
     * @return page result
     */
    public PageResult<WebhookLogVO> listWebhookLogs(WebhookLogQueryDTO query) {
        List<WebhookLogVO> list = webhookLogMapper.selectWebhookLogList(query);
        long total = webhookLogMapper.countWebhookLogs(query);
        return new PageResult<>(list, total);
    }

    /**
     * Push event to webhooks (async)
     * BL-49-01: Event triggered → async push to subscribed webhooks → log push result
     *
     * @param eventType event type
     * @param eventData event data
     */
    @Async
    public void pushEvent(String eventType, Map<String, Object> eventData) {
        // BL-49-05: Skip if webhook is DISABLED
        List<WebhookConfig> configs = webhookConfigMapper.selectEnabledByEventType(eventType);

        for (WebhookConfig config : configs) {
            pushToWebhook(config, eventType, eventData);
        }
    }

    /**
     * Push to single webhook with retry
     * BL-49-02: Push failure → exponential backoff retry → mark FAILURE if max retries reached
     * BL-49-04: Timeout control → default 5 seconds → timeout treated as failure
     *
     * @param config webhook config
     * @param eventType event type
     * @param eventData event data
     */
    private void pushToWebhook(WebhookConfig config, String eventType, Map<String, Object> eventData) {
        String requestBody;
        try {
            requestBody = objectMapper.writeValueAsString(eventData);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize event data for webhook {}", config.getId(), e);
            return;
        }

        int maxRetries = config.getRetryCount();
        int retryTimes = 0;
        boolean success = false;
        String errorMessage = null;
        Integer responseStatus = null;
        String responseBody = null;

        // BL-49-02: Exponential backoff retry (1s, 2s, 4s, 8s, 16s)
        while (retryTimes <= maxRetries && !success) {
            try {
                // BL-49-03: Generate HMAC-SHA256 signature
                String timestamp = String.valueOf(System.currentTimeMillis());
                String bodyHash = sha256(requestBody);
                String signature = generateHmacSignature(config.getSecretKey(), timestamp, bodyHash);

                // Build HTTP request
                HttpClient client = HttpClient.newBuilder()
                        .connectTimeout(Duration.ofSeconds(config.getTimeoutSeconds()))
                        .build();

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(config.getWebhookUrl()))
                        .header("Content-Type", "application/json")
                        .header("X-Webhook-Signature", signature)
                        .header("X-Webhook-Timestamp", timestamp)
                        .header("X-Webhook-Event-Type", eventType)
                        .timeout(Duration.ofSeconds(config.getTimeoutSeconds()))
                        .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                        .build();

                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                responseStatus = response.statusCode();
                responseBody = response.body();

                if (responseStatus >= 200 && responseStatus < 300) {
                    success = true;
                } else {
                    errorMessage = "HTTP " + responseStatus + ": " + responseBody;
                }

            } catch (Exception e) {
                errorMessage = e.getMessage();
                log.warn("Webhook push failed (attempt {}/{}): {}", retryTimes + 1, maxRetries + 1, e.getMessage());
            }

            if (!success && retryTimes < maxRetries) {
                // Exponential backoff: 1s, 2s, 4s, 8s, 16s
                long delayMs = (long) Math.pow(2, retryTimes) * 1000;
                try {
                    Thread.sleep(delayMs);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }

            retryTimes++;
        }

        // Save webhook log
        saveWebhookLog(config, eventType, eventData, requestBody, responseStatus, responseBody,
                retryTimes - 1, success ? STATUS_SUCCESS : STATUS_FAILURE, errorMessage);
    }

    /**
     * Save webhook log
     */
    private void saveWebhookLog(WebhookConfig config, String eventType, Map<String, Object> eventData,
                                String requestBody, Integer responseStatus, String responseBody,
                                int retryTimes, String status, String errorMessage) {
        try {
            WebhookLog log = new WebhookLog();
            log.setId(idGenerator.nextId());
            log.setWebhookId(config.getId());
            log.setEventType(eventType);
            log.setEventData(objectMapper.writeValueAsString(eventData));
            log.setRequestUrl(config.getWebhookUrl());
            log.setRequestBody(requestBody);
            log.setResponseStatus(responseStatus);
            log.setResponseBody(responseBody);
            log.setRetryTimes(retryTimes);
            log.setStatus(status);
            log.setErrorMessage(errorMessage);

            webhookLogMapper.insert(log);
        } catch (Exception e) {
            this.log.error("Failed to save webhook log", e);
        }
    }

    /**
     * Generate HMAC-SHA256 signature
     * BL-49-03: HMAC-SHA256(key=secret_key, data=timestamp+"\n"+body_hash)
     *
     * @param secretKey secret key
     * @param timestamp timestamp
     * @param bodyHash request body SHA-256 hash
     * @return Base64 encoded signature
     */
    private String generateHmacSignature(String secretKey, String timestamp, String bodyHash) {
        try {
            String data = timestamp + "\n" + bodyHash;
            Mac hmac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            hmac.init(secretKeySpec);
            byte[] signatureBytes = hmac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(signatureBytes);
        } catch (Exception e) {
            throw new RuntimeException("HMAC signature generation failed", e);
        }
    }

    /**
     * Calculate SHA-256 hash
     *
     * @param data input data
     * @return hex string
     */
    private String sha256(String data) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new RuntimeException("SHA-256 hash failed", e);
        }
    }
}
        try {
            config.setEventTypes(objectMapper.writeValueAsString(dto.getEventTypes()));
        } catch (JsonProcessingException e) {
            throw new BusinessException(ErrorCode.INTERNAL_ERROR, "事件类型序列化失败");
        }

        config.setSecretKey(dto.getSecretKey());
        config.setStatus(dto.getStatus());
        config.setRetryCount(dto.getRetryCount() != null ? dto.getRetryCount() : 5);
        config.setTimeoutSeconds(dto.getTimeoutSeconds() != null ? dto.getTimeoutSeconds() : 5);

        webhookConfigMapper.insert(config);
        return config.getId();
    }

    /**
     * Update webhook config
     *
     * @param id webhook config ID
     * @param dto webhook config DTO
     */
    @Transactional
    public void updateWebhookConfig(Long id, WebhookConfigDTO dto) {
        WebhookConfig config = webhookConfigMapper.selectById(id);
        if (config == null || config.getDeleted()) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Webhook 配置不存在");
        }

        config.setWebhookName(dto.getWebhookName());
        config.setWebhookUrl(dto.getWebhookUrl());
