package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

/**
 * 角色数据范围更新 DTO。
 *
 * <p>用于更新角色的自定义数据范围（部门列表）。
 *
 * <p>禁止字段：id、角色标识、租户标识、审计字段、逻辑删除标记、版本号。
 */
@Data
public class RoleDataScopeUpdateDTO {

    /**
     * 部门 ID 列表。
     *
     * <p>当角色 data_scope=CUSTOM 时，用户只能查看这些部门的数据。
     */
    @NotNull(message = "部门 ID 列表不能为空")
    private List<Long> deptIds;
}
