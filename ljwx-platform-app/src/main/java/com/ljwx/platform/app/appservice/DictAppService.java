package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.DictCreateDTO;
import com.ljwx.platform.app.domain.dto.DictDataCreateDTO;
import com.ljwx.platform.app.domain.dto.DictDataUpdateDTO;
import com.ljwx.platform.app.domain.dto.DictQueryDTO;
import com.ljwx.platform.app.domain.dto.DictUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysDictData;
import com.ljwx.platform.app.domain.entity.SysDictType;
import com.ljwx.platform.app.infra.mapper.SysDictDataMapper;
import com.ljwx.platform.app.infra.mapper.SysDictTypeMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
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

    public SysDictType getDictTypeById(Long id) {
        SysDictType dictType = dictTypeMapper.selectById(id);
        if (dictType == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "字典类型不存在");
        }
        return dictType;
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
    @CacheEvict(cacheNames = "dictData", allEntries = true)
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
    @CacheEvict(cacheNames = "dictData", allEntries = true)
    public void updateDictType(DictUpdateDTO dto) {
        SysDictType existing = getDictTypeById(dto.getId());
        existing.setDictName(dto.getDictName());
        existing.setDictType(dto.getDictType());
        if (dto.getStatus() != null) {
            existing.setStatus(dto.getStatus());
        }
        existing.setRemark(dto.getRemark());
        existing.setVersion(dto.getVersion());
        dictTypeMapper.updateById(existing);
    }

    @Transactional
    @CacheEvict(cacheNames = "dictData", allEntries = true)
    public void deleteDictType(Long id) {
        getDictTypeById(id);
        dictTypeMapper.deleteById(id);
    }

    public SysDictData getDictDataById(Long id) {
        SysDictData dictData = dictDataMapper.selectById(id);
        if (dictData == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "字典数据不存在");
        }
        return dictData;
    }

    @Transactional
    @CacheEvict(cacheNames = "dictData", allEntries = true)
    public Long createDictData(DictDataCreateDTO dto) {
        long id = idGenerator.nextId();

        SysDictData dictData = new SysDictData();
        dictData.setId(id);
        dictData.setDictType(dto.getDictType());
        dictData.setDictLabel(dto.getDictLabel());
        dictData.setDictValue(dto.getDictValue());
        dictData.setSortOrder(dto.getSortOrder() != null ? dto.getSortOrder() : 0);
        dictData.setStatus(dto.getStatus() != null ? dto.getStatus() : 1);
        dictData.setCssClass(dto.getCssClass());
        dictData.setListClass(dto.getListClass());
        dictData.setIsDefault(dto.getIsDefault() != null ? dto.getIsDefault() : Boolean.FALSE);
        dictData.setRemark(dto.getRemark());

        dictDataMapper.insert(dictData);
        return id;
    }

    @Transactional
    @CacheEvict(cacheNames = "dictData", allEntries = true)
    public void updateDictData(DictDataUpdateDTO dto) {
        SysDictData existing = getDictDataById(dto.getId());
        existing.setDictType(dto.getDictType());
        existing.setDictLabel(dto.getDictLabel());
        existing.setDictValue(dto.getDictValue());
        existing.setSortOrder(dto.getSortOrder());
        existing.setStatus(dto.getStatus());
        existing.setCssClass(dto.getCssClass());
        existing.setListClass(dto.getListClass());
        existing.setIsDefault(dto.getIsDefault());
        existing.setRemark(dto.getRemark());
        existing.setVersion(dto.getVersion());
        dictDataMapper.updateById(existing);
    }

    @Transactional
    @CacheEvict(cacheNames = "dictData", allEntries = true)
    public void deleteDictData(Long id) {
        getDictDataById(id);
        dictDataMapper.deleteById(id);
    }
}
