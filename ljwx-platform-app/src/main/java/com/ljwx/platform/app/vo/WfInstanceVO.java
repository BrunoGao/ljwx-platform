package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 流程实例 VO
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
public class WfInstanceVO {

    /**
     * 主键
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

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    private LocalDateTime updatedTime;
}
