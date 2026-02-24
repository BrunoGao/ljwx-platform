package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 更新租户套餐请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class TenantPackageUpdateDTO {

    private String name;

    private String menuIds;

    private Integer maxUsers;

    private Integer maxStorageMb;

    private Integer status;

    private Integer version;
}
