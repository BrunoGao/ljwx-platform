package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 配置查询条件（tenant_id 禁止出现，由 TenantLineInterceptor 自动注入）
 */
@Data
public class ConfigQueryDTO {

    /** 参数名称（模糊查询） */
    private String configName;

    /** 参数键名（模糊查询） */
    private String configKey;

    /** 系统内置：1-是，0-否 */
    private Integer configType;

    private Integer pageNum = 1;

    private Integer pageSize = 20;
}
