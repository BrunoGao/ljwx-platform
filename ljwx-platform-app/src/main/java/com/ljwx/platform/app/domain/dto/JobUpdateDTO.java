package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 更新定时任务请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class JobUpdateDTO {

    @NotNull
    private Long id;

    @NotBlank
    private String jobName;

    private String jobGroup;

    @NotBlank
    private String jobClassName;

    @NotBlank
    private String cronExpression;

    private String description;

    @NotNull
    private Integer version;
}
