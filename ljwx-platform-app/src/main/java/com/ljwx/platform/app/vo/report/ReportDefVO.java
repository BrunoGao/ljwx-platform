package com.ljwx.platform.app.vo.report;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Report Definition VO
 */
@Data
public class ReportDefVO {

    /**
     * Primary key
     */
    private Long id;

    /**
     * Report name
     */
    private String reportName;

    /**
     * Report unique identifier
     */
    private String reportKey;

    /**
     * Data source type
     */
    private String dataSourceType;

    /**
     * SQL query template
     */
    private String queryTemplate;

    /**
     * Column definition
     */
    private List<Map<String, Object>> columnDef;

    /**
     * Filter definition
     */
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
     * Created time
     */
    private LocalDateTime createdTime;

    /**
     * Updated time
     */
    private LocalDateTime updatedTime;
}
