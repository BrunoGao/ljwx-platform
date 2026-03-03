package com.ljwx.platform.app.dto.report;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * Report Definition Update DTO
 */
@Data
public class ReportDefUpdateDTO {

    /**
     * Report name
     */
    @NotBlank(message = "Report name cannot be blank")
    @Size(max = 100, message = "Report name cannot exceed 100 characters")
    private String reportName;

    /**
     * Data source type (MVP only supports SQL for PostgreSQL)
     */
    @NotBlank(message = "Data source type cannot be blank")
    @Pattern(regexp = "SQL", message = "Data source type must be SQL")
    private String dataSourceType;

    /**
     * SQL query template (using #{paramName} placeholders only)
     */
    @NotBlank(message = "Query template cannot be blank")
    private String queryTemplate;

    /**
     * Column definition list
     */
    @NotNull(message = "Column definition cannot be null")
    @Size(min = 1, message = "At least one column must be defined")
    private List<Map<String, Object>> columnDef;

    /**
     * Filter definition list (optional)
     */
    private List<Map<String, Object>> filterDef;

    /**
     * Status: 1 enabled, 0 disabled
     */
    @NotNull(message = "Status cannot be null")
    @Min(value = 0, message = "Status must be 0 or 1")
    @Max(value = 1, message = "Status must be 0 or 1")
    private Integer status;

    /**
     * Remark
     */
    @Size(max = 500, message = "Remark cannot exceed 500 characters")
    private String remark;
}
