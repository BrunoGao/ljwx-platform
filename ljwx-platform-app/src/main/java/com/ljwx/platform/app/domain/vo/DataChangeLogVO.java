package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 数据变更审计日志 VO。
 */
@Data
public class DataChangeLogVO {

    /** 主键ID */
    private Long id;

    /** 表名 */
    private String tableName;

    /** 记录ID */
    private Long recordId;

    /** 字段名 */
    private String fieldName;

    /** 变更前值 */
    private String oldValue;

    /** 变更后值 */
    private String newValue;

    /** 操作类型（UPDATE / DELETE） */
    private String operateType;

    /** 创建人 ID */
    private Long createdBy;

    /** 创建时间 */
    private LocalDateTime createdTime;
}
