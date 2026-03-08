package com.ljwx.platform.app.service;

import com.ljwx.platform.app.dto.OpenAppSecretDTO;
import com.ljwx.platform.app.infra.mapper.OpenAppSecretMapper;
import com.ljwx.platform.app.vo.OpenAppSecretVO;
import com.ljwx.platform.core.domain.OpenAppSecret;
import com.ljwx.platform.web.exception.BusinessException;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Open API Secret Service
 *
 * @author LJWX Platform
 * @since Phase 48
 */
@Service
@RequiredArgsConstructor
public class OpenAppSecretService {

    private final OpenAppSecretMapper secretMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final SensitiveDataCryptoService cryptoService;

    private static final int MAX_ACTIVE_SECRETS = 3;
    private static final String STATUS_ACTIVE = "ACTIVE";
    private static final String STATUS_EXPIRED = "EXPIRED";

    /**
     * Create new secret
     *
     * @param dto Secret DTO
     * @return Secret VO with plain text key
     */
    @Transactional
    public OpenAppSecretVO createSecret(OpenAppSecretDTO dto) {
        // BL-48-06: Check max active secrets limit
        int activeCount = secretMapper.countActiveByAppId(dto.getAppId());
        if (activeCount >= MAX_ACTIVE_SECRETS) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "每个应用最多保留 " + MAX_ACTIVE_SECRETS + " 个活跃密钥");
        }

        // BL-48-01: Generate 256-bit random secret key
        String plainSecretKey = generateSecretKey();

        // Get latest version
        Integer latestVersion = secretMapper.getLatestVersionByAppId(dto.getAppId());
        int newVersion = (latestVersion == null) ? 1 : latestVersion + 1;

        // Create secret entity
        OpenAppSecret secret = new OpenAppSecret();
        secret.setId(idGenerator.nextId());
        secret.setAppId(dto.getAppId());
        secret.setSecretKey(cryptoService.encrypt(plainSecretKey));
        secret.setSecretVersion(newVersion);
        secret.setStatus(STATUS_ACTIVE);

        // Calculate expiration time
        if (dto.getValidDays() != null && dto.getValidDays() > 0) {
            secret.setExpireTime(LocalDateTime.now().plusDays(dto.getValidDays()));
        }

        secretMapper.insert(secret);

        OpenAppSecretVO vo = new OpenAppSecretVO();
        BeanUtils.copyProperties(secret, vo);
        vo.setSecretKey(plainSecretKey);
        return vo;
    }

    /**
     * Rotate secret
     *
     * @param appId    Application ID
     * @param secretId Secret ID
     * @return New secret VO with plain text key
     */
    @Transactional
    public OpenAppSecretVO rotateSecret(Long appId, Long secretId) {
        // Get old secret
        OpenAppSecret oldSecret = secretMapper.selectById(secretId);
        if (oldSecret == null || !oldSecret.getAppId().equals(appId)) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "密钥不存在");
        }

        // BL-48-02: Mark old secret as EXPIRED
        oldSecret.setStatus(STATUS_EXPIRED);
        secretMapper.updateById(oldSecret);

        // Create new secret with version + 1
        OpenAppSecretDTO dto = new OpenAppSecretDTO();
        dto.setAppId(appId);
        dto.setValidDays(365); // Default 1 year

        return createSecret(dto);
    }

    /**
     * Delete secret (soft delete)
     *
     * @param appId    Application ID
     * @param secretId Secret ID
     */
    @Transactional
    public void deleteSecret(Long appId, Long secretId) {
        OpenAppSecret secret = secretMapper.selectById(secretId);
        if (secret == null || !secret.getAppId().equals(appId)) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "密钥不存在");
        }

        // BL-48-07: Soft delete
        secretMapper.deleteById(secretId);
    }

    /**
     * List secrets by app ID
     *
     * @param appId Application ID
     * @return Secret list (masked keys)
     */
    public List<OpenAppSecretVO> listSecrets(Long appId) {
        List<OpenAppSecret> secrets = secretMapper.listByAppId(appId);

        return secrets.stream().map(secret -> {
            OpenAppSecretVO vo = new OpenAppSecretVO();
            BeanUtils.copyProperties(secret, vo);
            vo.setSecretKey(maskSecretKey(secret.getSecretKey()));
            return vo;
        }).collect(Collectors.toList());
    }

    /**
     * Generate 256-bit random secret key
     *
     * @return Base64 encoded secret key
     */
    private String generateSecretKey() {
        try {
            KeyGenerator keyGen = KeyGenerator.getInstance("AES");
            SecureRandom secureRandom = new SecureRandom();
            keyGen.init(256, secureRandom);
            SecretKey secretKey = keyGen.generateKey();
            return Base64.getEncoder().encodeToString(secretKey.getEncoded());
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Failed to generate secret key", e);
        }
    }

    private String maskSecretKey(String storedSecretKey) {
        if (storedSecretKey == null || storedSecretKey.isBlank()) {
            return "";
        }

        String plainSecretKey = storedSecretKey;
        try {
            plainSecretKey = cryptoService.decrypt(storedSecretKey);
        } catch (BusinessException ignored) {
            // Keep compatibility with historical plaintext rows.
        }

        if (plainSecretKey.length() <= 8) {
            return "****";
        }
        return plainSecretKey.substring(0, 8) + "****";
    }
}
