package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.OpenAppDTO;
import com.ljwx.platform.app.domain.dto.OpenAppQueryDTO;
import com.ljwx.platform.app.domain.vo.OpenAppVO;
import com.ljwx.platform.app.infra.mapper.OpenAppMapper;
import com.ljwx.platform.core.domain.OpenApp;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Open API Application Service
 *
 * @author LJWX Platform
 * @since Phase 47
 */
@Service
@RequiredArgsConstructor
public class OpenApiAppService {

    private final OpenAppMapper openAppMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final SecureRandom secureRandom = new SecureRandom();

    /**
     * Create new application
     * Auto-generate app_key (UUID) and app_secret (128-bit random)
     *
     * @param dto application DTO
     * @return application VO with generated keys
     */
    @Transactional
    public OpenAppVO create(OpenAppDTO dto) {
        long id = idGenerator.nextId();

        // Generate app_key (UUID format)
        String appKey = UUID.randomUUID().toString().replace("-", "");

        // Generate app_secret (128-bit random, Base64 encoded)
        byte[] secretBytes = new byte[16];
        secureRandom.nextBytes(secretBytes);
        String appSecret = Base64.getEncoder().encodeToString(secretBytes);

        OpenApp app = new OpenApp();
        app.setId(id);
        app.setAppKey(appKey);
        app.setAppSecret(appSecret);
        app.setAppName(dto.getAppName());
        app.setAppType(dto.getAppType());
        app.setStatus("ENABLED");  // Default status
        app.setRateLimit(dto.getRateLimit());
        app.setIpWhitelist(dto.getIpWhitelist());
        app.setExpireTime(dto.getExpireTime());

        openAppMapper.insert(app);

        return convertToVO(app);
    }

    /**
     * Update application
     *
     * @param id application ID
     * @param dto application DTO
     */
    @Transactional
    public void update(Long id, OpenAppDTO dto) {
        OpenApp existing = openAppMapper.selectById(id);
        if (existing == null) {
            throw new IllegalArgumentException("应用不存在");
        }

        existing.setAppName(dto.getAppName());
        existing.setAppType(dto.getAppType());
        existing.setRateLimit(dto.getRateLimit());
        existing.setIpWhitelist(dto.getIpWhitelist());
        existing.setExpireTime(dto.getExpireTime());

        openAppMapper.updateById(existing);
    }

    /**
     * Delete application (soft delete)
     *
     * @param id application ID
     */
    @Transactional
    public void delete(Long id) {
        openAppMapper.deleteById(id);
    }

    /**
     * Get application by ID
     *
     * @param id application ID
     * @return application VO
     */
    public OpenAppVO getById(Long id) {
        OpenApp app = openAppMapper.selectById(id);
        if (app == null) {
            throw new IllegalArgumentException("应用不存在");
        }
        return convertToVO(app);
    }

    /**
     * List applications with pagination
     *
     * @param query query DTO
     * @return page result
     */
    public PageResult<OpenAppVO> list(OpenAppQueryDTO query) {
        List<OpenApp> apps = openAppMapper.selectList(query);
        long total = openAppMapper.countList(query);

        List<OpenAppVO> vos = apps.stream()
                .map(this::convertToVO)
                .collect(Collectors.toList());

        return new PageResult<>(vos, total);
    }

    /**
     * Regenerate application secret
     *
     * @param id application ID
     * @return new secret
     */
    @Transactional
    public String regenerateSecret(Long id) {
        OpenApp existing = openAppMapper.selectById(id);
        if (existing == null) {
            throw new IllegalArgumentException("应用不存在");
        }

        // Generate new app_secret (128-bit random, Base64 encoded)
        byte[] secretBytes = new byte[16];
        secureRandom.nextBytes(secretBytes);
        String newSecret = Base64.getEncoder().encodeToString(secretBytes);

        existing.setAppSecret(newSecret);
        openAppMapper.updateById(existing);

        return newSecret;
    }

    /**
     * Convert entity to VO
     *
     * @param app entity
     * @return VO
     */
    private OpenAppVO convertToVO(OpenApp app) {
        OpenAppVO vo = new OpenAppVO();
        vo.setId(app.getId());
        vo.setAppKey(app.getAppKey());
        vo.setAppName(app.getAppName());
        vo.setAppType(app.getAppType());
        vo.setStatus(app.getStatus());
        vo.setRateLimit(app.getRateLimit());
        vo.setIpWhitelist(app.getIpWhitelist());
        vo.setExpireTime(app.getExpireTime());
        vo.setCreatedTime(app.getCreatedTime());
        return vo;
    }
}
