package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 租户域名创建 DTO
 */
@Data
public class TenantDomainCreateDTO {

    /**
     * 域名（仅允许小写字母、数字、点、连字符）
     */
    @NotBlank(message = "域名不能为空")
    @Pattern(regexp = "^[a-z0-9.-]+$", message = "域名格式不正确，仅允许小写字母、数字、点、连字符")
    @Size(max = 200, message = "域名长度不能超过200个字符")
    private String domain;

    /**
     * 是否主域名
     */
    @NotNull(message = "是否主域名不能为空")
    private Boolean isPrimary;

    /**
     * 备注
     */
    @Size(max = 500, message = "备注长度不能超过500个字符")
    private String remark;
}
