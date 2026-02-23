package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.ConfigCreateDTO;
import com.ljwx.platform.app.domain.dto.ConfigQueryDTO;
import com.ljwx.platform.app.domain.dto.ConfigUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysConfig;
import com.ljwx.platform.app.infra.mapper.SysConfigMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 系统配置应用服务。
 *
 * <p>按 key 查询配置使用 Caffeine 缓存（TTL = 10 min），
 * 由 application.yml 中的 spring.cache.caffeine.spec 统一配置。
 * CacheEvict 在写操作时清空对应缓存。
 */
@Service
@RequiredArgsConstructor
public class ConfigAppService {

    private final SysConfigMapper configMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 分页查询系统配置列表。
     * TenantLineInterceptor 自动注入 tenant_id，无需手动设置。
     */
    public PageResult<SysConfig> listConfigs(ConfigQueryDTO query) {
        List<SysConfig> records = configMapper.selectList(query);
        long total = configMapper.countList(query);
        return new PageResult<>(records, total);
    }

    /**
     * 按键名查询配置值，使用 Caffeine 缓存（TTL = 10 min）。
     *
     * @param configKey 配置键名
     * @return 对应的系统配置实体，不存在时返回 null
     */
    @Cacheable(cacheNames = "sysConfig", key = "#configKey")
    public SysConfig getConfigByKey(String configKey) {
        return configMapper.selectByKey(configKey);
    }

    /**
     * 创建系统配置。
     * tenant_id 由 TenantLineInterceptor（MyBatis Interceptor）自动注入，Service 层禁止手动设置。
     */
    @Transactional
    public Long createConfig(ConfigCreateDTO dto) {
        long id = idGenerator.nextId();

        SysConfig config = new SysConfig();
        config.setId(id);
        config.setConfigName(dto.getConfigName());
        config.setConfigKey(dto.getConfigKey());
        config.setConfigValue(dto.getConfigValue());
        config.setConfigType(dto.getConfigType() != null ? dto.getConfigType() : 0);
        config.setRemark(dto.getRemark());

        configMapper.insert(config);
        return id;
    }

    /**
     * 更新系统配置，并清除对应配置缓存。
     */
    @Transactional
    @CacheEvict(cacheNames = "sysConfig", key = "#dto.configKey")
    public void updateConfig(ConfigUpdateDTO dto) {
        SysConfig existing = configMapper.selectById(dto.getId());
        existing.setConfigName(dto.getConfigName());
        existing.setConfigKey(dto.getConfigKey());
        existing.setConfigValue(dto.getConfigValue());
        if (dto.getConfigType() != null) {
            existing.setConfigType(dto.getConfigType());
        }
        existing.setRemark(dto.getRemark());
        existing.setVersion(dto.getVersion());
        configMapper.updateById(existing);
    }
}
