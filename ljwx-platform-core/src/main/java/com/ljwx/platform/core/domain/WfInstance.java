package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 流程实例实体
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class WfInstance extends BaseEntity {

    /**
     * 主键（雪花 ID）
     */
    private Long id;

    /**
     * 流程定义ID
     */
    private Long definitionId;

    /**
     * 业务主键
     */
    private String businessKey;

    /**
     * 业务类型
     */
    private String businessType;

    /**
     * 发起人ID
     */
    private Long initiatorId;

    /**
     * 当前节点
     */
    private String currentNode;

    /**
     * 状态: RUNNING/COMPLETED/REJECTED/CANCELLED
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
}
