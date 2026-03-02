package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 流程任务实体
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class WfTask extends BaseEntity {

    /**
     * 主键（雪花 ID）
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
}
