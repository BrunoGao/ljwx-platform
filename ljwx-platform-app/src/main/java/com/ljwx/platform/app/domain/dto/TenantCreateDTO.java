package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 租户创建 DTO。
 */
@Data
public class TenantCreateDTO {

    @NotBlank(message = "租户名称不能为空")
    @Size(max = 100, message = "租户名称长度不能超过 100")
    private String name;

    @NotBlank(message = "租户编码不能为空")
    @Size(max = 50, message = "租户编码长度不能超过 50")
    private String code;
}
