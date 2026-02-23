package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 定时任务查询条件（tenant_id 禁止出现，由 TenantLineInterceptor 自动注入）
 */
@Data
public class JobQueryDTO {

    private String jobName;

    private Integer status;

    private Integer pageNum = 1;

    private Integer pageSize = 20;
}
