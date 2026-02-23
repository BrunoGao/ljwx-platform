package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 创建系统配置请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class ConfigCreateDTO {

    @NotBlank
    private String configName;

    @NotBlank
    private String configKey;

    @NotBlank
    private String configValue;

    private Integer configType = 0;

    private String remark;
}
