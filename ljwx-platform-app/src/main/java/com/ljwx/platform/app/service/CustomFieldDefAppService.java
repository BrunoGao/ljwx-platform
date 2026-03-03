package com.ljwx.platform.app.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.ljwx.platform.app.domain.CustomFieldDef;
import com.ljwx.platform.app.dto.form.CustomFieldDefCreateDTO;
import com.ljwx.platform.app.dto.form.CustomFieldDefUpdateDTO;
import com.ljwx.platform.app.mapper.CustomFieldDefMapper;
import com.ljwx.platform.app.vo.form.CustomFieldDefVO;
import com.ljwx.platform.core.exception.BusinessException;
import com.ljwx.platform.data.snowflake.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Custom field definition service
 */
@Service
@RequiredArgsConstructor
public class CustomFieldDefAppService {

    private final CustomFieldDefMapper customFieldDefMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * List custom fields by entity type
     */
    public List<CustomFieldDefVO> listByEntityType(String entityType) {
        LambdaQueryWrapper<CustomFieldDef> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(CustomFieldDef::getEntityType, entityType);
        wrapper.orderByAsc(CustomFieldDef::getSortOrder);

        List<CustomFieldDef> list = customFieldDefMapper.selectList(wrapper);
        return list.stream()
                .map(this::toVO)
                .collect(Collectors.toList());
    }

    /**
     * Create custom field definition
     */
    @Transactional
    public Long create(CustomFieldDefCreateDTO dto) {
        // Check if field_key already exists for this entity type
        LambdaQueryWrapper<CustomFieldDef> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(CustomFieldDef::getEntityType, dto.getEntityType());
        wrapper.eq(CustomFieldDef::getFieldKey, dto.getFieldKey());
        Long count = customFieldDefMapper.selectCount(wrapper);
        if (count > 0) {
            throw new BusinessException("Field key already exists for this entity type");
        }

        CustomFieldDef customFieldDef = new CustomFieldDef();
        customFieldDef.setId(idGenerator.nextId());
        customFieldDef.setEntityType(dto.getEntityType());
        customFieldDef.setFieldKey(dto.getFieldKey());
        customFieldDef.setFieldLabel(dto.getFieldLabel());
        customFieldDef.setFieldType(dto.getFieldType());
        customFieldDef.setRequired(dto.getRequired());
        customFieldDef.setSortOrder(dto.getSortOrder());
        customFieldDef.setOptions(dto.getOptions());

        customFieldDefMapper.insert(customFieldDef);
        return customFieldDef.getId();
    }

    /**
     * Update custom field definition
     */
    @Transactional
    public void update(Long id, CustomFieldDefUpdateDTO dto) {
        CustomFieldDef customFieldDef = customFieldDefMapper.selectById(id);
        if (customFieldDef == null) {
            throw new BusinessException("Custom field definition not found");
        }

        customFieldDef.setFieldLabel(dto.getFieldLabel());
        customFieldDef.setRequired(dto.getRequired());
        customFieldDef.setSortOrder(dto.getSortOrder());
        customFieldDef.setOptions(dto.getOptions());

        customFieldDefMapper.updateById(customFieldDef);
    }

    /**
     * Delete custom field definition (soft delete)
     */
    @Transactional
    public void delete(Long id) {
        CustomFieldDef customFieldDef = customFieldDefMapper.selectById(id);
        if (customFieldDef == null) {
            throw new BusinessException("Custom field definition not found");
        }

        customFieldDefMapper.deleteById(id);
    }

    /**
     * Convert entity to VO
     */
    private CustomFieldDefVO toVO(CustomFieldDef customFieldDef) {
        CustomFieldDefVO vo = new CustomFieldDefVO();
        BeanUtils.copyProperties(customFieldDef, vo);
        return vo;
    }
}
