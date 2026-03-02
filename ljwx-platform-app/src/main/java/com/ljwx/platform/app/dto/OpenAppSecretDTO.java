package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * Open API Secret DTO
 *
 * @author LJWX Platform
 * @since Phase 48
 */
@Data
public class OpenAppSecretDTO {

    /**
     * Application ID
     */
    @NotNull(message = "应用 ID 不能为空")
    private Long appId;

    /**
     * Valid days (default: 365)
     */
    @Min(value = 1, message = "有效天数必须大于 0")
    private Integer validDays = 365;
}
