package com.ljwx.platform.app.domain.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 任务执行日志查询 DTO
 */
@Data
public class TaskExecutionLogQueryDTO {

    /**
     * 任务名称（模糊查询）
     */
    private String taskName;

    /**
     * 任务分组
     */
    private String taskGroup;

    /**
     * 执行状态
     */
    private String status;

    /**
     * 开始时间（起）
     */
    private LocalDateTime startTimeBegin;

    /**
     * 开始时间（止）
     */
    private LocalDateTime startTimeEnd;

    /**
     * 页码
     */
    private Integer pageNum = 1;

    /**
     * 每页大小
     */
    private Integer pageSize = 10;
}
