package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.domain.dto.TenantCancelDTO;
import com.ljwx.platform.app.domain.dto.TenantFreezeDTO;
import com.ljwx.platform.app.service.TenantInitializer;
import com.ljwx.platform.app.service.TenantLifecycleService;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * 租户生命周期管理 Controller。
 */
@RestController
@RequestMapping("/api/v1/tenants")
@RequiredArgsConstructor
public class TenantLifecycleController {

    private final TenantLifecycleService lifecycleService;
    private final TenantInitializer tenantInitializer;

    /**
     * 冻结租户。
     *
     * @param id  租户 ID
     * @param dto 冻结请求
     * @return 操作结果
     */
    @PreAuthorize("hasAuthority('system:tenant:freeze')")
    @PostMapping("/{id}/freeze")
    public Result<Void> freeze(@PathVariable Long id, @Valid @RequestBody TenantFreezeDTO dto) {
        lifecycleService.freeze(id, dto.getReason());
        return Result.ok();
    }

    /**
     * 解冻租户。
     *
     * @param id 租户 ID
     * @return 操作结果
     */
    @PreAuthorize("hasAuthority('system:tenant:unfreeze')")
    @PostMapping("/{id}/unfreeze")
    public Result<Void> unfreeze(@PathVariable Long id) {
        lifecycleService.unfreeze(id);
        return Result.ok();
    }

    /**
     * 注销租户。
     *
     * @param id  租户 ID
     * @param dto 注销请求
     * @return 操作结果
     */
    @PreAuthorize("hasAuthority('system:tenant:cancel')")
    @PostMapping("/{id}/cancel")
    public Result<Void> cancel(@PathVariable Long id, @Valid @RequestBody TenantCancelDTO dto) {
        lifecycleService.cancel(id, dto.getReason());
        return Result.ok();
    }

    /**
     * 初始化租户（创建默认管理员、角色、部门）。
     *
     * @param id 租户 ID
     * @return 操作结果
     */
    @PreAuthorize("hasAuthority('system:tenant:init')")
    @PostMapping("/{id}/initialize")
    public Result<Void> initialize(@PathVariable Long id) {
        tenantInitializer.initialize(id);
        return Result.ok();
    }
}
