package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 租户套餐实体，对应 sys_tenant_package 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysTenantPackage extends BaseEntity {

    private Long id;

    /** 套餐名称 */
    private String name;

    /** 菜单ID列表（逗号分隔） */
    private String menuIds;

    /** 最大用户数 */
    private Integer maxUsers;

    /** 最大存储空间（MB） */
    private Integer maxStorageMb;

    /** 状态：1=正常，0=停用 */
    private Integer status;
}
