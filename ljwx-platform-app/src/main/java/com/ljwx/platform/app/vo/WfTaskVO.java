package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 流程任务 VO
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
public class WfTaskVO {

    /**
     * 主键
     */
    private Long id;

    /**
     * 流程实例ID
     */
    private Long instanceId;

    /**
     * 任务名称
     */
    private String taskName;

    /**
     * 任务类型: APPROVAL/NOTIFY
     */
    private String taskType;

    /**
     * 处理人ID
     */
    private Long assigneeId;

    /**
     * 状态: PENDING/APPROVED/REJECTED
     */
    private String status;

    /**
     * 审批意见
     */
    private String comment;

    /**
     * 处理时间
     */
    private LocalDateTime handleTime;

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    private LocalDateTime updatedTime;
}
