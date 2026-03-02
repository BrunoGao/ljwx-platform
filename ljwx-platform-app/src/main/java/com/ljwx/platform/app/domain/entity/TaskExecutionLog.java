package com.ljwx.platform.app.domain.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.ljwx.platform.core.entity.BaseEntity;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.time.LocalDateTime;

/**
 * 任务执行日志实体
 */
@Data
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
@TableName("sys_task_execution_log")
public class TaskExecutionLog extends BaseEntity {

    /**
     * 任务名称
     */
    private String taskName;

    /**
     * 任务分组
     */
    private String taskGroup;

    /**
     * 任务参数
     */
    private String taskParams;

    /**
     * 执行状态: SUCCESS / FAILURE / RUNNING
     */
    private String status;

    /**
     * 开始时间
     */
    private LocalDateTime startTime;

    /**
     * 结束时间
     */
    private LocalDateTime endTime;

    /**
     * 执行耗时（毫秒）
     */
    private Integer duration;

    /**
     * 执行结果
     */
    private String result;

    /**
     * 错误信息
     */
    private String errorMessage;

    /**
     * 错误堆栈
     */
    private String errorStack;

    /**
     * 服务器地址
     */
    private String serverIp;

    /**
     * 服务器名称
     */
    private String serverName;
}
