package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.util.List;

/**
 * 角色数据范围 VO。
 *
 * <p>返回角色的自定义数据范围信息。
 *
 * <p>禁止字段：tenantId, deleted, createdBy, updatedBy, version。
 */
@Data
public class RoleDataScopeVO {

    /** 角色 ID */
    private Long roleId;

    /** 部门 ID 列表 */
    private List<Long> deptIds;

    /** 部门名称列表 */
    private List<String> deptNames;
}
