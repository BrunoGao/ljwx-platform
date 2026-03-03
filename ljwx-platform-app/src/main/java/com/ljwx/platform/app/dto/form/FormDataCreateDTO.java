package com.ljwx.platform.app.dto.form;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.Map;

/**
 * Form data create DTO
 */
@Data
public class FormDataCreateDTO {

    /**
     * Form definition ID
     */
    @NotNull(message = "Form definition ID cannot be null")
    private Long formDefId;

    /**
     * Form field values (key=fieldKey, value=field value)
     */
    @NotNull(message = "Field values cannot be null")
    private Map<String, Object> fieldValues;
}
