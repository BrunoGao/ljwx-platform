package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程定义实体
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class WfDefinition extends BaseEntity {

    /**
     * 主键（雪花 ID）
     */
    private Long id;

    /**
     * 流程标识
     */
    private String flowKey;

    /**
     * 流程名称
     */
    private String flowName;

    /**
     * 版本号
     */
    private Integer flowVersion;

    /**
     * 流程配置（JSON格式）
     */
    private String flowConfig;

    /**
     * 状态: DRAFT/PUBLISHED/ARCHIVED
     */
    private String status;
}
