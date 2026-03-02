package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

import java.util.List;

/**
 * Webhook Configuration DTO
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Data
public class WebhookConfigDTO {

    /**
     * Webhook Name
     */
    @NotBlank(message = "Webhook 名称不能为空")
    private String webhookName;

    /**
     * Webhook URL
     */
    @NotBlank(message = "Webhook URL 不能为空")
    @Pattern(regexp = "^https?://.*", message = "URL 格式不正确")
    private String webhookUrl;

    /**
     * Event Types
     */
    @NotNull(message = "事件类型不能为空")
    private List<String> eventTypes;

    /**
     * Secret Key for HMAC signature
     */
    @NotBlank(message = "签名密钥不能为空")
    private String secretKey;

    /**
     * Status: ENABLED / DISABLED
     */
    @NotBlank(message = "状态不能为空")
    private String status;

    /**
     * Max Retry Count (default: 5)
     */
    private Integer retryCount = 5;

    /**
     * Timeout in seconds (default: 5)
     */
    private Integer timeoutSeconds = 5;
}
