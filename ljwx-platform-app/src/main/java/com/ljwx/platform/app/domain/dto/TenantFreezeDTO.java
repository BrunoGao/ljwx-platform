package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 租户冻结请求 DTO。
 */
@Data
public class TenantFreezeDTO {

    @NotBlank(message = "冻结原因不能为空")
    @Size(max = 500, message = "冻结原因长度不能超过500字符")
    private String reason;
}
