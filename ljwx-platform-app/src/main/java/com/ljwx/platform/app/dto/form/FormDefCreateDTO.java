package com.ljwx.platform.app.dto.form;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Form definition create DTO
 */
@Data
public class FormDefCreateDTO {

    /**
     * Form name
     */
    @NotBlank(message = "Form name cannot be blank")
    @Size(max = 100, message = "Form name cannot exceed 100 characters")
    private String formName;

    /**
     * Form unique key (lowercase letters + numbers + underscore)
     */
    @NotBlank(message = "Form key cannot be blank")
    @Size(max = 100, message = "Form key cannot exceed 100 characters")
    @Pattern(regexp = "^[a-z][a-z0-9_]*$", message = "Form key must start with lowercase letter and contain only lowercase letters, numbers, and underscores")
    private String formKey;

    /**
     * Form JSON Schema (fields, validation, layout)
     */
    @NotNull(message = "Schema cannot be null")
    private Object schema;

    /**
     * Remark
     */
    @Size(max = 500, message = "Remark cannot exceed 500 characters")
    private String remark;
}
