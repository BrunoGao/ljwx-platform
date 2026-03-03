package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 菜单实体，对应 sys_menu 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysMenu extends BaseEntity {

    private Long id;

    /** 父节点 ID，0 = 根节点 */
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
}
