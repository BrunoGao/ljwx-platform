package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 流程定义 VO
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
public class WfDefinitionVO {

    /**
     * 主键
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

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    private LocalDateTime updatedTime;
}
