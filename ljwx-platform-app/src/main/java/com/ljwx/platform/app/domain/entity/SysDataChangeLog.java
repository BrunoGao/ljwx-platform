package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 数据变更审计日志实体，对应 sys_data_change_log 表。
 *
 * <p>记录业务数据的变更历史（UPDATE / DELETE 操作），
 * 由 DataChangeInterceptor（data 模块）自动捕获并异步写入。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysDataChangeLog extends BaseEntity {

    /** 主键ID（Snowflake） */
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
}
