package com.ljwx.platform.app.dto.form;

import jakarta.validation.constraints.*;
import lombok.Data;

/**
 * Form definition update DTO
 */
@Data
public class FormDefUpdateDTO {

    /**
     * Form name
     */
    @NotBlank(message = "Form name cannot be blank")
    @Size(max = 100, message = "Form name cannot exceed 100 characters")
    private String formName;

    /**
     * Form JSON Schema (fields, validation, layout)
     */
    @NotNull(message = "Schema cannot be null")
    private Object schema;

    /**
     * Status: 1=enabled, 0=disabled
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
