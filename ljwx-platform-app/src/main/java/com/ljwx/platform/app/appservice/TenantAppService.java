package com.ljwx.platform.app.appservice;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.ljwx.platform.app.domain.Tenant;
import com.ljwx.platform.app.domain.dto.TenantCreateDTO;
import com.ljwx.platform.app.domain.dto.TenantQueryDTO;
import com.ljwx.platform.app.domain.dto.TenantUpdateDTO;
import com.ljwx.platform.app.domain.vo.TenantVO;
import com.ljwx.platform.app.mapper.TenantMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 租户管理应用服务。
 */
@Service
@RequiredArgsConstructor
public class TenantAppService {

    private final TenantMapper tenantMapper;
    private final SnowflakeIdGenerator idGenerator;

    public PageResult<TenantVO> listTenants(TenantQueryDTO query) {
        LambdaQueryWrapper<Tenant> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Tenant::getDeleted, false);

        if (StringUtils.hasText(query.getName())) {
            wrapper.like(Tenant::getName, query.getName().trim());
        }
        if (StringUtils.hasText(query.getCode())) {
            wrapper.like(Tenant::getCode, query.getCode().trim());
        }
        if (query.getStatus() != null) {
            wrapper.eq(Tenant::getStatus, query.getStatus());
        }
        wrapper.orderByDesc(Tenant::getCreatedTime);

        Page<Tenant> page = new Page<>(query.getPageNum(), query.getPageSize());
        Page<Tenant> result = tenantMapper.selectPage(page, wrapper);
        List<TenantVO> rows = result.getRecords().stream()
                .map(this::toVO)
                .collect(Collectors.toList());
        return new PageResult<>(rows, result.getTotal());
    }

    public TenantVO getTenant(Long id) {
        Tenant tenant = requireTenant(id);
        return toVO(tenant);
    }

    @Transactional
    public Long createTenant(TenantCreateDTO dto) {
        ensureCodeUnique(dto.getCode(), null);

        Tenant tenant = new Tenant();
        tenant.setId(idGenerator.nextId());
        tenant.setName(dto.getName().trim());
        tenant.setCode(dto.getCode().trim());
        tenant.setStatus(1);
        tenant.setLifecycleStatus("ACTIVE");
        tenant.setTenantId(0L);
        tenant.setDeleted(false);
        tenant.setVersion(1);

        tenantMapper.insert(tenant);
        return tenant.getId();
    }

    @Transactional
    public void updateTenant(Long id, TenantUpdateDTO dto) {
        Tenant tenant = requireTenant(id);

        if (StringUtils.hasText(dto.getCode())) {
            ensureCodeUnique(dto.getCode(), id);
            tenant.setCode(dto.getCode().trim());
        }
        if (StringUtils.hasText(dto.getName())) {
            tenant.setName(dto.getName().trim());
        }
        if (dto.getStatus() != null) {
            tenant.setStatus(dto.getStatus());
        }

        tenantMapper.updateById(tenant);
    }

    @Transactional
    public void deleteTenant(Long id) {
        Tenant tenant = requireTenant(id);
        tenant.setDeleted(true);
        tenantMapper.updateById(tenant);
    }

    private Tenant requireTenant(Long id) {
        Tenant tenant = tenantMapper.selectById(id);
        if (tenant == null || Boolean.TRUE.equals(tenant.getDeleted())) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在");
        }
        return tenant;
    }

    private void ensureCodeUnique(String code, Long excludeId) {
        LambdaQueryWrapper<Tenant> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Tenant::getCode, code.trim())
                .eq(Tenant::getDeleted, false);
        Tenant existing = tenantMapper.selectOne(wrapper);
        if (existing != null && (excludeId == null || !existing.getId().equals(excludeId))) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "租户编码已存在");
        }
    }

    private TenantVO toVO(Tenant tenant) {
        TenantVO vo = new TenantVO();
        BeanUtils.copyProperties(tenant, vo);
        return vo;
    }
}
