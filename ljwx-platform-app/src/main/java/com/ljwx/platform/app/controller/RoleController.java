package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.RoleAppService;
import com.ljwx.platform.app.domain.dto.RoleCreateDTO;
import com.ljwx.platform.app.domain.dto.RoleQueryDTO;
import com.ljwx.platform.app.domain.dto.RoleUpdateDTO;
import com.ljwx.platform.app.domain.vo.RoleVO;
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
 * 角色管理 Controller。
 */
@RestController
@RequestMapping("/api/roles")
@RequiredArgsConstructor
public class RoleController {

    private final RoleAppService roleAppService;

    @PreAuthorize("hasAuthority('role:read')")
    @GetMapping
    public Result<PageResult<RoleVO>> list(RoleQueryDTO query) {
        return Result.ok(roleAppService.listRoles(query));
    }

    @PreAuthorize("hasAuthority('role:read')")
    @GetMapping("/{id}")
    public Result<RoleVO> getById(@PathVariable Long id) {
        return Result.ok(roleAppService.getRole(id));
    }

    @PreAuthorize("hasAuthority('role:write')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid RoleCreateDTO dto) {
        return Result.ok(roleAppService.createRole(dto));
    }

    @PreAuthorize("hasAuthority('role:write')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid RoleUpdateDTO dto) {
        roleAppService.updateRole(id, dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('role:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        roleAppService.deleteRole(id);
        return Result.ok();
    }
}
