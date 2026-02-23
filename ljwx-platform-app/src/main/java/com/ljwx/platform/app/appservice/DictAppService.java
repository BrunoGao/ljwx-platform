package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.DictCreateDTO;
import com.ljwx.platform.app.domain.dto.DictQueryDTO;
import com.ljwx.platform.app.domain.dto.DictUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysDictData;
import com.ljwx.platform.app.domain.entity.SysDictType;
import com.ljwx.platform.app.infra.mapper.SysDictDataMapper;
import com.ljwx.platform.app.infra.mapper.SysDictTypeMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 字典应用服务。
 *
 * <p>字典类型列表和字典数据均通过 Caffeine 缓存（TTL = 10 min），
 * 由 application.yml 中的 spring.cache.caffeine.spec 统一配置。
 * CacheEvict 在写操作时清空对应缓存。
 */
@Service
@RequiredArgsConstructor
public class DictAppService {

    private final SysDictTypeMapper dictTypeMapper;
    private final SysDictDataMapper dictDataMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 分页查询字典类型列表。
     * TenantLineInterceptor 自动注入 tenant_id，无需手动设置。
     */
    public PageResult<SysDictType> listDictTypes(DictQueryDTO query) {
        List<SysDictType> records = dictTypeMapper.selectList(query);
        long total = dictTypeMapper.countList(query);
        return new PageResult<>(records, total);
    }

    /**
     * 按字典类型查询字典数据项，使用 Caffeine 缓存（TTL = 10 min）。
     *
     * @param dictType 字典类型标识，如 sys_user_sex
     * @return 该类型下的所有字典数据项列表
     */
    @Cacheable(cacheNames = "dictData", key = "#dictType")
    public List<SysDictData> getDictDataByType(String dictType) {
        return dictDataMapper.selectByDictType(dictType);
    }

    /**
     * 创建字典类型。
     * tenant_id 由 TenantLineInterceptor（MyBatis Interceptor）自动注入，Service 层禁止手动设置。
     */
    @Transactional
    public Long createDictType(DictCreateDTO dto) {
        long id = idGenerator.nextId();

        SysDictType dictType = new SysDictType();
        dictType.setId(id);
        dictType.setDictName(dto.getDictName());
        dictType.setDictType(dto.getDictType());
        dictType.setStatus(dto.getStatus() != null ? dto.getStatus() : 1);
        dictType.setRemark(dto.getRemark());

        dictTypeMapper.insert(dictType);
        return id;
    }

    /**
     * 更新字典类型，并清除对应字典数据缓存。
     */
    @Transactional
    @CacheEvict(cacheNames = "dictData", key = "#dto.dictType")
    public void updateDictType(DictUpdateDTO dto) {
        SysDictType existing = dictTypeMapper.selectById(dto.getId());
        existing.setDictName(dto.getDictName());
        existing.setDictType(dto.getDictType());
        if (dto.getStatus() != null) {
            existing.setStatus(dto.getStatus());
        }
        existing.setRemark(dto.getRemark());
        existing.setVersion(dto.getVersion());
        dictTypeMapper.updateById(existing);
    }
}
