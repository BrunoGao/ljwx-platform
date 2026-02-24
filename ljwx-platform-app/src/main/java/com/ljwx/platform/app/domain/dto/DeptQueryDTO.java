package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 部门查询条件（tenant_id 禁止出现，由 TenantLineInterceptor 自动注入）
 */
@Data
public class DeptQueryDTO {

    /** 部门名称（模糊匹配） */
    private String name;

    /** 状态：1=正常，0=停用 */
    private Integer status;
}
