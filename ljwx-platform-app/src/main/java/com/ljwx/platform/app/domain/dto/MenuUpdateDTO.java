package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 更新菜单 DTO（tenant_id 禁止出现，由 TenantLineInterceptor 自动注入）。
 */
@Data
public class MenuUpdateDTO {

    /** 父节点 ID */
    private Long parentId;

    /** 菜单名称 */
    private String name;

    /** 路由路径 */
    private String path;

    /** 前端组件路径 */
    private String component;

    /** 图标 */
    private String icon;

    /** 排序 */
    private Integer sort;

    /** 菜单类型：0=目录 1=菜单 2=按钮 */
    private Integer menuType;

    /** 权限字符串 */
    private String permission;

    /** 显示状态：1=显示 0=隐藏 */
    private Integer visible;

    /** 乐观锁版本号（可选，未提供时跳过版本校验） */
    private Integer version;
}
