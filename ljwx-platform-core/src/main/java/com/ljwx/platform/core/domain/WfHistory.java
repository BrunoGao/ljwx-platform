package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程历史实体
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class WfHistory extends BaseEntity {

    /**
     * 主键（雪花 ID）
     */
    private Long id;

    /**
     * 流程实例ID
     */
    private Long instanceId;

    /**
     * 任务ID
     */
    private Long taskId;

    /**
     * 操作: START/APPROVE/REJECT/CANCEL
     */
    private String action;

    /**
     * 操作人ID
     */
    private Long operatorId;

    /**
     * 操作意见
     */
    private String comment;
}
