package com.ljwx.platform.app.dto.form;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * Form data query DTO
 */
@Data
public class FormDataQueryDTO {

    /**
     * Form definition ID (required to prevent full table scan)
     */
    @NotNull(message = "Form definition ID cannot be null")
    private Long formDefId;

    /**
     * Creator user ID (optional filter)
     */
    private Long creatorId;

    /**
     * Created time start (optional, must be provided with endTime)
     */
    private LocalDateTime startTime;

    /**
     * Created time end (optional, must be provided with startTime)
     */
    private LocalDateTime endTime;

    /**
     * Page number
     */
    @Min(value = 1, message = "Page number must be at least 1")
    private Integer pageNum = 1;

    /**
     * Page size
     */
    @Min(value = 1, message = "Page size must be at least 1")
    @Max(value = 100, message = "Page size cannot exceed 100")
    private Integer pageSize = 10;
}
