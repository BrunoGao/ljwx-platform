package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Report Definition Entity
 */
@Data
@TableName(value = "rpt_report_def", autoResultMap = true)
public class RptReportDef {

    /**
     * Primary key (Snowflake ID)
     */
    @TableId
    private Long id;

    /**
     * Tenant ID
     */
    private Long tenantId;

    /**
     * Report name
     */
    private String reportName;

    /**
     * Report unique identifier
     */
    private String reportKey;

    /**
     * Data source type (MVP only supports SQL for PostgreSQL)
     */
    private String dataSourceType;

    /**
     * SQL query template (using #{paramName} placeholders)
     */
    private String queryTemplate;

    /**
     * Column definition (column name, title, type, width, format)
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<Map<String, Object>> columnDef;

    /**
     * Filter definition (parameter name, type, label, required)
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<Map<String, Object>> filterDef;

    /**
     * Status: 1 enabled, 0 disabled
     */
    private Integer status;

    /**
     * Remark
     */
    private String remark;

    /**
     * Created by user ID
     */
    private Long createdBy;

    /**
     * Created time
     */
    private LocalDateTime createdTime;

    /**
     * Updated by user ID
     */
    private Long updatedBy;

    /**
     * Updated time
     */
    private LocalDateTime updatedTime;

    /**
     * Soft delete flag
     */
    private Boolean deleted;

    /**
     * Optimistic lock version
     */
    private Integer version;
}
