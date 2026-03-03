package com.ljwx.platform.app.dto.report;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.Map;

/**
 * Report Execute DTO
 */
@Data
public class ReportExecuteDTO {

    /**
     * Runtime parameters (corresponding to filter_def parameters, max 20 parameters)
     */
    @Size(max = 20, message = "Maximum 20 parameters allowed")
    private Map<String, Object> params;

    /**
     * Page number (starting from 1)
     */
    @Min(value = 1, message = "Page number must be at least 1")
    private Integer pageNum;

    /**
     * Page size (max 1000 rows)
     */
    @Min(value = 1, message = "Page size must be at least 1")
    @Max(value = 1000, message = "Page size cannot exceed 1000")
    private Integer pageSize;
}
