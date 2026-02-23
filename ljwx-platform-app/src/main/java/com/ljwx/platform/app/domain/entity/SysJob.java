package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 定时任务实体，对应 sys_job 表。
 * JobKey 格式：name="{id}", group="TENANT_{tenantId}"（per-tenant 隔离）
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysJob extends BaseEntity {

    /** 任务ID（Snowflake） */
    private Long id;

    /** 任务名称 */
    private String jobName;

    /** 任务分组，默认 DEFAULT */
    private String jobGroup;

    /** 任务执行类全路径（由 QuartzJobDispatcher 动态加载） */
    private String jobClassName;

    /** Cron 表达式 */
    private String cronExpression;

    /** 任务描述 */
    private String description;

    /** 状态：1-正常，0-暂停 */
    private Integer status;
}
