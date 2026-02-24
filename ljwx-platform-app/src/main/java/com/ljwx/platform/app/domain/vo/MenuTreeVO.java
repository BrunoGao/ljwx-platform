package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.util.List;

/**
 * 菜单树形视图对象（嵌套结构）。
 */
@Data
public class MenuTreeVO {

    private Long id;
    private Long parentId;
    private String name;
    private String path;
    private String component;
    private String icon;
    private Integer sort;
    /** 菜单类型：0=目录 1=菜单 2=按钮 */
    private Integer menuType;
    private String permission;
    /** 显示状态：1=显示 0=隐藏 */
    private Integer visible;
    /** 子节点列表 */
    private List<MenuTreeVO> children;
}
