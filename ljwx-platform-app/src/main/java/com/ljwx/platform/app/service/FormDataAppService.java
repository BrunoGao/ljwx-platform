package com.ljwx.platform.app.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.ljwx.platform.app.domain.FormData;
import com.ljwx.platform.app.domain.FormDef;
import com.ljwx.platform.app.dto.form.FormDataCreateDTO;
import com.ljwx.platform.app.dto.form.FormDataQueryDTO;
import com.ljwx.platform.app.dto.form.FormDataUpdateDTO;
import com.ljwx.platform.app.mapper.FormDataMapper;
import com.ljwx.platform.app.mapper.FormDefMapper;
import com.ljwx.platform.app.vo.form.FormDataVO;
import com.ljwx.platform.core.exception.BusinessException;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Form data service
 */
@Service
@RequiredArgsConstructor
public class FormDataAppService {

    private final FormDataMapper formDataMapper;
    private final FormDefMapper formDefMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentUserHolder currentUserHolder;

    /**
     * Paginated query for form data (metadata filtering only)
     */
    public PageResult<FormDataVO> list(FormDataQueryDTO query) {
        // Validate date range if provided
        if (query.getStartTime() != null && query.getEndTime() != null) {
            if (query.getEndTime().isBefore(query.getStartTime())) {
                throw new BusinessException("End time must be after start time");
            }
            Duration duration = Duration.between(query.getStartTime(), query.getEndTime());
            if (duration.toDays() > 90) {
                throw new BusinessException("Date range cannot exceed 90 days");
            }
        } else if (query.getStartTime() != null || query.getEndTime() != null) {
            throw new BusinessException("Start time and end time must be provided together");
        }

        LambdaQueryWrapper<FormData> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FormData::getFormDefId, query.getFormDefId());

        if (query.getCreatorId() != null) {
            wrapper.eq(FormData::getCreatorId, query.getCreatorId());
        }
        if (query.getStartTime() != null && query.getEndTime() != null) {
            wrapper.between(FormData::getCreatedTime, query.getStartTime(), query.getEndTime());
        }

        wrapper.orderByDesc(FormData::getCreatedTime);

        Page<FormData> page = new Page<>(query.getPageNum(), query.getPageSize());
        IPage<FormData> result = formDataMapper.selectPage(page, wrapper);

        List<FormDataVO> voList = result.getRecords().stream()
                .map(this::toVO)
                .collect(Collectors.toList());

        return new PageResult<>(voList, result.getTotal());
    }

    /**
     * Get form data by ID
     */
    public FormDataVO getById(Long id) {
        FormData formData = formDataMapper.selectById(id);
        if (formData == null) {
            throw new BusinessException("Form data not found");
        }
        return toVO(formData);
    }

    /**
     * Create form data (inject creatorId and creatorDeptId from SecurityContext)
     */
    @Transactional
    public Long create(FormDataCreateDTO dto) {
        // Validate form definition exists and is enabled
        FormDef formDef = formDefMapper.selectById(dto.getFormDefId());
        if (formDef == null) {
            throw new BusinessException("Form definition not found");
        }
        if (formDef.getStatus() != 1) {
            throw new BusinessException("Form definition is disabled");
        }

        FormData formData = new FormData();
        formData.setId(idGenerator.nextId());
        formData.setFormDefId(dto.getFormDefId());
        formData.setFieldValues(dto.getFieldValues());

        // Inject creatorId and creatorDeptId from SecurityContext
        Long currentUserId = currentUserHolder.getUserId();
        formData.setCreatorId(currentUserId != null ? currentUserId : 0L);
        formData.setCreatorDeptId(0L); // TODO: Get from user's department

        formDataMapper.insert(formData);
        return formData.getId();
    }

    /**
     * Update form data
     */
    @Transactional
    public void update(Long id, FormDataUpdateDTO dto) {
        FormData formData = formDataMapper.selectById(id);
        if (formData == null) {
            throw new BusinessException("Form data not found");
        }

        formData.setFieldValues(dto.getFieldValues());
        formDataMapper.updateById(formData);
    }

    /**
     * Convert entity to VO
     */
    private FormDataVO toVO(FormData formData) {
        FormDataVO vo = new FormDataVO();
        BeanUtils.copyProperties(formData, vo);
        return vo;
    }
}
