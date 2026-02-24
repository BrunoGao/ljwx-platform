package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

/**
 * 创建角色 DTO（不含 tenantId，由后端自动注入）。
 */
@Data
public class RoleCreateDTO {

    @NotBlank(message = "角色名称不能为空")
    private String name;

    @NotBlank(message = "角色编码不能为空")
    private String code;

    private String description;

    /** 权限 ID 列表 */
    private List<Long> permissionIds;
}
