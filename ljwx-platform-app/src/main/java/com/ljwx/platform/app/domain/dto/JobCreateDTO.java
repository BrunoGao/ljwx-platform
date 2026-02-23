package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 创建定时任务请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class JobCreateDTO {

    @NotBlank
    private String jobName;

    private String jobGroup;

    @NotBlank
    private String jobClassName;

    @NotBlank
    private String cronExpression;

    private String description;
}
