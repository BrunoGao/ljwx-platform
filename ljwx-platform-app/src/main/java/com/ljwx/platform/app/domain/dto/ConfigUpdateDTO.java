package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 更新系统配置请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class ConfigUpdateDTO {

    @NotNull
    private Long id;

    @NotBlank
    private String configName;

    @NotBlank
    private String configKey;

    @NotBlank
    private String configValue;

    private Integer configType;

    private String remark;

    @NotNull
    private Integer version;
}
