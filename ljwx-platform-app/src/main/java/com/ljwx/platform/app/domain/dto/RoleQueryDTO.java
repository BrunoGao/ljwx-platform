package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 角色查询条件（tenant_id 禁止出现，由 TenantLineInterceptor 自动注入）。
 */
@Data
public class RoleQueryDTO {

    /** 角色名称（模糊查询） */
    private String name;

    /** 角色编码（精确查询） */
    private String code;

    /** 状态：1-启用，0-禁用 */
    private Integer status;

    private Integer pageNum = 1;

    private Integer pageSize = 20;

    public int getOffset() {
        return (pageNum - 1) * pageSize;
    }
}
