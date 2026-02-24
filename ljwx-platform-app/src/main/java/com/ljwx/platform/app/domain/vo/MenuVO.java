package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 菜单视图对象（平铺列表）。
 */
@Data
public class MenuVO {

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
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
}
