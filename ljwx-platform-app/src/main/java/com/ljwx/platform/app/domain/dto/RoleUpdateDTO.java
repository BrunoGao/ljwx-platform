package com.ljwx.platform.app.domain.dto;

import lombok.Data;

import java.util.List;

/**
 * 更新角色 DTO（租户由 TenantLineInterceptor 自动注入）。
 */
@Data
public class RoleUpdateDTO {

    private String name;
    private String code;
    private String description;
    /** 状态：1-启用，0-禁用 */
    private Integer status;
    /** 权限 ID 列表（提供时全量替换） */
    private List<Long> permissionIds;
    /** 乐观锁版本号（可选，未提供时跳过版本校验） */
    private Integer version;
}
