package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.TenantAppService;
import com.ljwx.platform.app.domain.dto.TenantCreateDTO;
import com.ljwx.platform.app.domain.dto.TenantQueryDTO;
import com.ljwx.platform.app.domain.dto.TenantUpdateDTO;
import com.ljwx.platform.app.domain.vo.TenantVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 租户管理控制器。
 */
@RestController
@RequestMapping("/api/v1/tenants")
@RequiredArgsConstructor
public class TenantController {

    private final TenantAppService tenantAppService;

    @PreAuthorize("hasAuthority('system:tenant:list')")
    @GetMapping
    public Result<PageResult<TenantVO>> list(TenantQueryDTO query) {
        return Result.ok(tenantAppService.listTenants(query));
    }

    @PreAuthorize("hasAuthority('system:tenant:detail')")
    @GetMapping("/{id}")
    public Result<TenantVO> getById(@PathVariable Long id) {
        return Result.ok(tenantAppService.getTenant(id));
    }

    @PreAuthorize("hasAuthority('system:tenant:create')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody TenantCreateDTO dto) {
        return Result.ok(tenantAppService.createTenant(dto));
    }

    @PreAuthorize("hasAuthority('system:tenant:update')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody TenantUpdateDTO dto) {
        tenantAppService.updateTenant(id, dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('system:tenant:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        tenantAppService.deleteTenant(id);
        return Result.ok();
    }
}
