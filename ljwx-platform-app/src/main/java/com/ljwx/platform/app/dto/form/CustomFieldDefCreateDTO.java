package com.ljwx.platform.app.dto.form;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * Custom field definition create DTO
 */
@Data
public class CustomFieldDefCreateDTO {

    /**
     * Entity type (USER/DEPT)
     */
    @NotBlank(message = "Entity type cannot be blank")
    @Size(max = 50, message = "Entity type cannot exceed 50 characters")
    @Pattern(regexp = "USER|DEPT", message = "Entity type must be USER or DEPT")
    private String entityType;

    /**
     * Field unique key (lowercase letters + numbers + underscore)
     */
    @NotBlank(message = "Field key cannot be blank")
    @Size(max = 100, message = "Field key cannot exceed 100 characters")
    @Pattern(regexp = "^[a-z][a-z0-9_]*$", message = "Field key must start with lowercase letter and contain only lowercase letters, numbers, and underscores")
    private String fieldKey;

    /**
     * Field display label
     */
    @NotBlank(message = "Field label cannot be blank")
    @Size(max = 100, message = "Field label cannot exceed 100 characters")
    private String fieldLabel;

    /**
     * Field type (TEXT/NUMBER/DATE/SELECT/CHECKBOX)
     */
    @NotBlank(message = "Field type cannot be blank")
    @Pattern(regexp = "TEXT|NUMBER|DATE|SELECT|CHECKBOX", message = "Field type must be TEXT, NUMBER, DATE, SELECT, or CHECKBOX")
    private String fieldType;

    /**
     * Is required
     */
    @NotNull(message = "Required flag cannot be null")
    private Boolean required;

    /**
     * Sort order
     */
    @Min(value = 0, message = "Sort order must be at least 0")
    private Integer sortOrder = 0;

    /**
     * Options for SELECT/CHECKBOX (JSON array)
     */
    private List<Object> options;
}
