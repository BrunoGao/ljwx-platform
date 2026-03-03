package com.ljwx.platform.app.dto.form;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.Map;

/**
 * Form data update DTO
 */
@Data
public class FormDataUpdateDTO {

    /**
     * Form field values (full replacement)
     */
    @NotNull(message = "Field values cannot be null")
    private Map<String, Object> fieldValues;
}
