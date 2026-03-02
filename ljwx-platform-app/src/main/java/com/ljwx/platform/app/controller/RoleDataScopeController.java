package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.RoleDataScopeAppService;
import com.ljwx.platform.app.domain.dto.RoleDataScopeUpdateDTO;
import com.ljwx.platform.app.domain.vo.RoleDataScopeVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * 角色数据范围 Controller。
 *
 * <p>管理角色的自定义数据范围（CUSTOM 类型）。
 *
 * <p>权限标识：
 * <ul>
 *   <li>查询：system:role:query</li>
 *   <li>更新：system:role:edit</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/roles")
@RequiredArgsConstructor
public class RoleDataScopeController {

    private final RoleDataScopeAppService roleDataScopeAppService;

    /**
     * 查询角色的自定义数据范围。
     *
     * @param roleId 角色 ID
     * @return 角色数据范围 VO
     */
    @PreAuthorize("hasAuthority('system:role:query')")
    @GetMapping("/{roleId}/data-scope")
    public Result<RoleDataScopeVO> getDataScope(@PathVariable Long roleId) {
        return Result.ok(roleDataScopeAppService.getByRoleId(roleId));
    }

    /**
     * 更新角色的自定义数据范围。
     *
     * @param roleId 角色 ID
     * @param dto    更新 DTO
     * @return 成功响应
     */
    @PreAuthorize("hasAuthority('system:role:edit')")
    @PutMapping("/{roleId}/data-scope")
    public Result<Void> updateDataScope(
            @PathVariable Long roleId,
            @Valid @RequestBody RoleDataScopeUpdateDTO dto) {
        roleDataScopeAppService.update(roleId, dto);
        return Result.ok();
    }
}
