package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 角色自定义数据范围实体，对应 sys_role_data_scope 表。
 *
 * <p>用于存储角色的自定义部门数据范围（当角色 data_scope=CUSTOM 时生效）。
 *
 * <p>继承 {@link BaseEntity} 获得 7 个审计字段：
 * tenant_id, created_by, created_time, updated_by, updated_time, deleted, version。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class RoleDataScope extends BaseEntity {

    /** 主键（雪花 ID） */
    private Long id;

    /** 角色 ID */
    private Long roleId;

    /** 部门 ID */
    private Long deptId;
}
