package com.ljwx.platform.app.dto.form;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * Custom field definition update DTO
 */
@Data
public class CustomFieldDefUpdateDTO {

    /**
     * Field display label
     */
    @NotBlank(message = "Field label cannot be blank")
    @Size(max = 100, message = "Field label cannot exceed 100 characters")
    private String fieldLabel;

    /**
     * Is required
     */
    @NotNull(message = "Required flag cannot be null")
    private Boolean required;

    /**
     * Sort order
     */
    @Min(value = 0, message = "Sort order must be at least 0")
    private Integer sortOrder;

    /**
     * Options for SELECT/CHECKBOX (JSON array)
     */
    private List<Object> options;
}
