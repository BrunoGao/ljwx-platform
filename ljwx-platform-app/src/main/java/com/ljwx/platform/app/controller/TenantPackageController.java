package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.TenantPackageAppService;
import com.ljwx.platform.app.domain.dto.TenantPackageCreateDTO;
import com.ljwx.platform.app.domain.dto.TenantPackageQueryDTO;
import com.ljwx.platform.app.domain.dto.TenantPackageUpdateDTO;
import com.ljwx.platform.app.domain.vo.TenantPackageVO;
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
 * 租户套餐管理 Controller。
 */
@RestController
@RequestMapping("/api/v1/tenant-packages")
@RequiredArgsConstructor
public class TenantPackageController {

    private final TenantPackageAppService tenantPackageAppService;

    @PreAuthorize("hasAuthority('system:tenant-package:list')")
    @GetMapping
    public Result<PageResult<TenantPackageVO>> list(TenantPackageQueryDTO query) {
        return Result.ok(tenantPackageAppService.listPackages(query));
    }

    @PreAuthorize("hasAuthority('system:tenant-package:detail')")
    @GetMapping("/{id}")
    public Result<TenantPackageVO> getById(@PathVariable Long id) {
        return Result.ok(tenantPackageAppService.getPackage(id));
    }

    @PreAuthorize("hasAuthority('system:tenant-package:create')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid TenantPackageCreateDTO dto) {
        return Result.ok(tenantPackageAppService.createPackage(dto));
    }

    @PreAuthorize("hasAuthority('system:tenant-package:update')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid TenantPackageUpdateDTO dto) {
        tenantPackageAppService.updatePackage(id, dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('system:tenant-package:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        tenantPackageAppService.deletePackage(id);
        return Result.ok();
    }
}
