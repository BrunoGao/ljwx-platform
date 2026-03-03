package com.ljwx.platform.app.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.ljwx.platform.app.domain.FormDef;
import com.ljwx.platform.app.dto.form.FormDefCreateDTO;
import com.ljwx.platform.app.dto.form.FormDefQueryDTO;
import com.ljwx.platform.app.dto.form.FormDefUpdateDTO;
import com.ljwx.platform.app.mapper.FormDefMapper;
import com.ljwx.platform.app.vo.form.FormDefVO;
import com.ljwx.platform.core.exception.BusinessException;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.data.snowflake.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Form definition service
 */
@Service
@RequiredArgsConstructor
public class FormDefAppService {

    private final FormDefMapper formDefMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * Paginated query for form definitions
     */
    public PageResult<FormDefVO> list(FormDefQueryDTO query) {
        LambdaQueryWrapper<FormDef> wrapper = new LambdaQueryWrapper<>();

        if (StringUtils.hasText(query.getFormName())) {
            wrapper.like(FormDef::getFormName, query.getFormName());
        }
        if (StringUtils.hasText(query.getFormKey())) {
            wrapper.like(FormDef::getFormKey, query.getFormKey());
        }
        if (query.getStatus() != null) {
            wrapper.eq(FormDef::getStatus, query.getStatus());
        }

        wrapper.orderByDesc(FormDef::getCreatedTime);

        Page<FormDef> page = new Page<>(query.getPageNum(), query.getPageSize());
        IPage<FormDef> result = formDefMapper.selectPage(page, wrapper);

        List<FormDefVO> voList = result.getRecords().stream()
                .map(this::toVO)
                .collect(Collectors.toList());

        return new PageResult<>(voList, result.getTotal());
    }

    /**
     * Get form definition by ID
     */
    public FormDefVO getById(Long id) {
        FormDef formDef = formDefMapper.selectById(id);
        if (formDef == null) {
            throw new BusinessException("Form definition not found");
        }
        return toVO(formDef);
    }

    /**
     * Create form definition
     */
    @Transactional
    public Long create(FormDefCreateDTO dto) {
        // Check if form_key already exists
        LambdaQueryWrapper<FormDef> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FormDef::getFormKey, dto.getFormKey());
        Long count = formDefMapper.selectCount(wrapper);
        if (count > 0) {
            throw new BusinessException("Form key already exists");
        }

        FormDef formDef = new FormDef();
        formDef.setId(idGenerator.nextId());
        formDef.setFormName(dto.getFormName());
        formDef.setFormKey(dto.getFormKey());
        formDef.setSchema(dto.getSchema());
        formDef.setStatus(1);
        formDef.setRemark(dto.getRemark());

        formDefMapper.insert(formDef);
        return formDef.getId();
    }

    /**
     * Update form definition
     */
    @Transactional
    public void update(Long id, FormDefUpdateDTO dto) {
        FormDef formDef = formDefMapper.selectById(id);
        if (formDef == null) {
            throw new BusinessException("Form definition not found");
        }

        formDef.setFormName(dto.getFormName());
        formDef.setSchema(dto.getSchema());
        formDef.setStatus(dto.getStatus());
        formDef.setRemark(dto.getRemark());

        formDefMapper.updateById(formDef);
    }

    /**
     * Delete form definition (soft delete)
     */
    @Transactional
    public void delete(Long id) {
        FormDef formDef = formDefMapper.selectById(id);
        if (formDef == null) {
            throw new BusinessException("Form definition not found");
        }

        formDefMapper.deleteById(id);
    }

    /**
     * Convert entity to VO
     */
    private FormDefVO toVO(FormDef formDef) {
        FormDefVO vo = new FormDefVO();
        BeanUtils.copyProperties(formDef, vo);
        return vo;
    }
}
