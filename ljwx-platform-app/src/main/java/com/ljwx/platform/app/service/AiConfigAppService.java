package com.ljwx.platform.app.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.ljwx.platform.app.domain.AiConfig;
import com.ljwx.platform.app.dto.ai.AiConfigUpdateDTO;
import com.ljwx.platform.app.mapper.AiConfigMapper;
import com.ljwx.platform.app.vo.ai.AiConfigVO;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * AI 配置服务
 *
 * @author LJWX Platform
 */
@Slf4j
@Service
public class AiConfigAppService {

    private final AiConfigMapper aiConfigMapper;
    private final SensitiveDataCryptoService cryptoService;
    private final String legacyAiKey;

    public AiConfigAppService(
            AiConfigMapper aiConfigMapper,
            SensitiveDataCryptoService cryptoService,
            @Value("${ljwx.ai.legacy-aes-key:}") String legacyAiKey) {
        this.aiConfigMapper = aiConfigMapper;
        this.cryptoService = cryptoService;
        this.legacyAiKey = legacyAiKey;
    }

    /**
     * 获取当前租户的 AI 配置
     *
     * @return AI 配置 VO
     */
    public AiConfigVO getConfig() {
        Long tenantId = CurrentTenantHolder.get();
        AiConfig config = getActiveConfig(tenantId);

        AiConfigVO vo = new AiConfigVO();
        vo.setProvider(config.getProvider());
        vo.setModelName(config.getModelName());
        vo.setApiKeyMasked(maskApiKey(decryptApiKey(config.getApiKeyEncrypted())));
        vo.setBaseUrl(config.getBaseUrl());
        vo.setTemperature(config.getTemperature());
        vo.setMaxTokens(config.getMaxTokens());
        vo.setEnabled(config.getEnabled());
        return vo;
    }

    /**
     * 更新 AI 配置
     *
     * @param dto 更新 DTO
     */
    @Transactional
    public void updateConfig(AiConfigUpdateDTO dto) {
        Long tenantId = CurrentTenantHolder.get();
        AiConfig config = getActiveConfig(tenantId);

        config.setProvider(dto.getProvider());
        config.setModelName(dto.getModelName());
        config.setApiKeyEncrypted(cryptoService.encrypt(dto.getApiKey()));
        config.setBaseUrl(dto.getBaseUrl());
        config.setTemperature(dto.getTemperature());
        config.setMaxTokens(dto.getMaxTokens());

        aiConfigMapper.updateById(config);
    }

    /**
     * 获取当前租户的活跃配置
     *
     * @param tenantId 租户 ID
     * @return AI 配置
     */
    public AiConfig getActiveConfig(Long tenantId) {
        LambdaQueryWrapper<AiConfig> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(AiConfig::getTenantId, tenantId)
                .eq(AiConfig::getEnabled, true)
                .eq(AiConfig::getDeleted, false);

        AiConfig config = aiConfigMapper.selectOne(wrapper);
        if (config == null) {
            throw new BusinessException("AI 功能未启用");
        }
        return config;
    }

    private String decryptApiKey(String encryptedApiKey) {
        try {
            return cryptoService.decrypt(encryptedApiKey);
        } catch (BusinessException ex) {
            return decryptLegacyApiKey(encryptedApiKey);
        }
    }

    private String decryptLegacyApiKey(String encryptedApiKey) {
        try {
            SecretKeySpec keySpec = new SecretKeySpec(legacyAiKeyBytes(), "AES");
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.DECRYPT_MODE, keySpec);
            byte[] decrypted = cipher.doFinal(Base64.getDecoder().decode(encryptedApiKey));
            return new String(decrypted, StandardCharsets.UTF_8);
        } catch (BusinessException ex) {
            throw ex;
        } catch (Exception e) {
            throw new BusinessException("API Key 解密失败", e);
        }
    }

    private byte[] legacyAiKeyBytes() {
        if (legacyAiKey == null || legacyAiKey.isBlank()) {
            throw new BusinessException("API Key 解密失败：请配置 ljwx.ai.legacy-aes-key 以兼容旧版数据");
        }
        byte[] keyBytes = legacyAiKey.getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length != 16 && keyBytes.length != 24 && keyBytes.length != 32) {
            throw new BusinessException("API Key 解密失败：ljwx.ai.legacy-aes-key 长度必须为 16/24/32 字节");
        }
        return keyBytes;
    }

    /**
     * 脱敏 API Key
     *
     * @param apiKey 明文 API Key
     * @return 脱敏后的 API Key（sk-***...***xxxx）
     */
    private String maskApiKey(String apiKey) {
        if (apiKey == null || apiKey.length() < 8) {
            return "***";
        }
        String prefix = apiKey.substring(0, 3);
        String suffix = apiKey.substring(apiKey.length() - 4);
        return prefix + "***...***" + suffix;
    }
}
