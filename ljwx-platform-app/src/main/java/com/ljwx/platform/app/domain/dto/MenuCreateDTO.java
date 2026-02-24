package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 创建菜单 DTO（tenant_id 禁止出现，由后端自动注入）。
 */
@Data
public class MenuCreateDTO {

    /** 父节点 ID，0 = 根节点 */
    @NotNull(message = "父节点 ID 不能为空")
    private Long parentId;

    /** 菜单名称 */
    @NotBlank(message = "菜单名称不能为空")
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
    @NotNull(message = "菜单类型不能为空")
    private Integer menuType;

    /** 权限字符串 */
    private String permission;

    /** 显示状态：1=显示 0=隐藏 */
    private Integer visible;
}
