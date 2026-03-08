package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.domain.vo.PermissionVO;
import com.ljwx.platform.app.infra.mapper.SysPermissionMapper;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 权限 Controller（只读）。
 * 权限列表用于角色配置时的权限选择器。
 */
@RestController
@RequestMapping({"/api/v1/permissions", "/api/permissions"})
@RequiredArgsConstructor
public class PermissionController {

    private final SysPermissionMapper permissionMapper;

    @PreAuthorize("hasAuthority('role:read')")
    @GetMapping
    public Result<List<PermissionVO>> list() {
        return Result.ok(permissionMapper.selectAll());
    }
}
