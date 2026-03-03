package com.ljwx.platform.app.dto.report;

import lombok.Data;

/**
 * Report Definition Query DTO
 */
@Data
public class ReportDefQueryDTO {

    /**
     * Report name (fuzzy search)
     */
    private String reportName;

    /**
     * Report key (exact match)
     */
    private String reportKey;

    /**
     * Status: 1 enabled, 0 disabled
     */
    private Integer status;

    /**
     * Page number (starting from 1)
     */
    private Integer pageNum;

    /**
     * Page size
     */
    private Integer pageSize;

    /**
     * Calculate offset for SQL LIMIT
     */
    public Integer getOffset() {
        if (pageNum == null || pageSize == null) {
            return null;
        }
        return (pageNum - 1) * pageSize;
    }
}
