package com.ljwx.platform.app.dto.report;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * Report Definition Create DTO
 */
@Data
public class ReportDefCreateDTO {

    /**
     * Report name
     */
    @NotBlank(message = "Report name cannot be blank")
    @Size(max = 100, message = "Report name cannot exceed 100 characters")
    private String reportName;

    /**
     * Report unique identifier (lowercase letters, numbers, underscores only)
     */
    @NotBlank(message = "Report key cannot be blank")
    @Size(max = 100, message = "Report key cannot exceed 100 characters")
    @Pattern(regexp = "^[a-z][a-z0-9_]*$", message = "Report key must start with lowercase letter and contain only lowercase letters, numbers, and underscores")
    private String reportKey;

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
     * Remark
     */
    @Size(max = 500, message = "Remark cannot exceed 500 characters")
    private String remark;
}
