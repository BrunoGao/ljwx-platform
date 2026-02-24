package com.ljwx.platform.app.domain.vo;

import lombok.Data;

/**
 * 权限视图对象。
 */
@Data
public class PermissionVO {

    private Long id;
    private String name;
    /** 权限标识，格式：resource:action，如 user:read */
    private String code;
    /** 资源部分，如 user */
    private String resource;
    /** 操作部分，如 read */
    private String action;
}
