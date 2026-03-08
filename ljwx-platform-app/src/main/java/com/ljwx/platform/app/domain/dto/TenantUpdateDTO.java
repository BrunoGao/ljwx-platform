package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 租户更新 DTO。
 */
@Data
public class TenantUpdateDTO {

    @Size(max = 100, message = "租户名称长度不能超过 100")
    private String name;

    @Size(max = 50, message = "租户编码长度不能超过 50")
    private String code;

    private Integer status;
}
