package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 租户注销请求 DTO。
 */
@Data
public class TenantCancelDTO {

    @NotBlank(message = "注销原因不能为空")
    @Size(max = 500, message = "注销原因长度不能超过500字符")
    private String reason;
}
