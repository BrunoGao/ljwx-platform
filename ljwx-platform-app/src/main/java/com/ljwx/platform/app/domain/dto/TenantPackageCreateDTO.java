package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 创建租户套餐请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class TenantPackageCreateDTO {

    @NotBlank
    private String name;

    private String menuIds = "";

    private Integer maxUsers = 100;

    private Integer maxStorageMb = 1024;
}
