package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.TenantDomainAppService;
import com.ljwx.platform.app.domain.dto.TenantDomainCreateDTO;
import com.ljwx.platform.app.domain.vo.TenantDomainVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 租户域名控制器
 */
@RestController
@RequestMapping("/api/v1/tenant/domains")
@RequiredArgsConstructor
public class TenantDomainController {

    private final TenantDomainAppService tenantDomainAppService;

    /**
     * 查询当前租户域名列表
     */
    @PreAuthorize("hasAuthority('tenant:domain:list')")
    @GetMapping
    public Result<List<TenantDomainVO>> list() {
        return Result.ok(tenantDomainAppService.list());
    }

    /**
     * 查询域名详情
     */
    @PreAuthorize("hasAuthority('tenant:domain:query')")
    @GetMapping("/{id}")
    public Result<TenantDomainVO> getById(@PathVariable Long id) {
        return Result.ok(tenantDomainAppService.getById(id));
    }

    /**
     * 创建域名
     */
    @PreAuthorize("hasAuthority('tenant:domain:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody TenantDomainCreateDTO dto) {
        return Result.ok(tenantDomainAppService.create(dto));
    }

    /**
     * 删除域名（软删除）
     */
    @PreAuthorize("hasAuthority('tenant:domain:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        tenantDomainAppService.delete(id);
        return Result.ok();
    }

    /**
     * 验证域名
     */
    @PreAuthorize("hasAuthority('tenant:domain:verify')")
    @PostMapping("/{id}/verify")
    public Result<Void> verify(@PathVariable Long id) {
        tenantDomainAppService.verify(id);
        return Result.ok();
    }

    /**
     * 设置为主域名
     */
    @PreAuthorize("hasAuthority('tenant:domain:setPrimary')")
    @PostMapping("/{id}/set-primary")
    public Result<Void> setPrimary(@PathVariable Long id) {
        tenantDomainAppService.setPrimary(id);
        return Result.ok();
    }
}
