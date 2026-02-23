package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 字典查询条件（tenant_id 禁止出现，由 TenantLineInterceptor 自动注入）
 */
@Data
public class DictQueryDTO {

    /** 字典名称（模糊查询） */
    private String dictName;

    /** 字典类型（精确查询） */
    private String dictType;

    /** 状态：1-正常，0-停用 */
    private Integer status;

    private Integer pageNum = 1;

    private Integer pageSize = 20;
}
