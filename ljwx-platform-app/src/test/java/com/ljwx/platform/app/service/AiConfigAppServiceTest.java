package com.ljwx.platform.app.service;

import com.ljwx.platform.app.domain.AiConfig;
import com.ljwx.platform.app.mapper.AiConfigMapper;
import com.ljwx.platform.app.vo.ai.AiConfigVO;
import com.ljwx.platform.web.exception.BusinessException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AiConfigAppServiceTest {

    private final AiConfigMapper aiConfigMapper = mock(AiConfigMapper.class);
    private final SensitiveDataCryptoService cryptoService = mock(SensitiveDataCryptoService.class);

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void getConfigFallsBackToConfiguredLegacyKey() throws Exception {
        AiConfigAppService service = new AiConfigAppService(aiConfigMapper, cryptoService, legacyKey());
        AiConfig config = enabledConfig(encryptLegacy("demo-key-1234"));

        when(aiConfigMapper.selectOne(any())).thenReturn(config);
        when(cryptoService.decrypt(config.getApiKeyEncrypted()))
                .thenThrow(new BusinessException("敏感数据解密失败"));

        setTenantId(1L);

        AiConfigVO vo = service.getConfig();

        assertThat(vo.getApiKeyMasked()).isEqualTo("dem***...***1234");
    }

    @Test
    void getConfigFailsClearlyWhenLegacyKeyIsMissing() throws Exception {
        AiConfigAppService service = new AiConfigAppService(aiConfigMapper, cryptoService, "");
        AiConfig config = enabledConfig(encryptLegacy("demo-key-1234"));

        when(aiConfigMapper.selectOne(any())).thenReturn(config);
        when(cryptoService.decrypt(config.getApiKeyEncrypted()))
                .thenThrow(new BusinessException("敏感数据解密失败"));

        setTenantId(1L);

        assertThatThrownBy(service::getConfig)
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("ljwx.ai.legacy-aes-key");
    }

    private static AiConfig enabledConfig(String encryptedApiKey) {
        AiConfig config = new AiConfig();
        config.setProvider("OPENAI");
        config.setModelName("gpt-4o-mini");
        config.setApiKeyEncrypted(encryptedApiKey);
        config.setBaseUrl("https://unit.test");
        config.setTemperature(BigDecimal.valueOf(0.7));
        config.setMaxTokens(512);
        config.setEnabled(true);
        return config;
    }

    private static void setTenantId(Long tenantId) {
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken("tester", "n/a");
        authentication.setDetails(Map.of("tenantId", tenantId));
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private static String encryptLegacy(String plainText) throws Exception {
        SecretKeySpec keySpec = new SecretKeySpec(legacyKey().getBytes(StandardCharsets.UTF_8), "AES");
        Cipher cipher = Cipher.getInstance("AES");
        cipher.init(Cipher.ENCRYPT_MODE, keySpec);
        byte[] encrypted = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(encrypted);
    }

    private static String legacyKey() {
        byte[] keyBytes = {
                108, 106, 119, 120, 45, 97, 105, 45,
                107, 101, 121, 45, 50, 48, 50, 54
        };
        return new String(keyBytes, StandardCharsets.UTF_8);
    }
}
