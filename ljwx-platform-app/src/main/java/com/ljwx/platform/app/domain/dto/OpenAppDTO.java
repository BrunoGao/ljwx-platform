package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * Open API Application Create/Update DTO
 *
 * @author LJWX Platform
 * @since Phase 47
 */
@Data
public class OpenAppDTO {

    /**
     * Application Name
     */
    @NotBlank(message = "应用名称不能为空")
    private String appName;

    /**
     * Application Type: INTERNAL / EXTERNAL
     */
    @NotBlank(message = "应用类型不能为空")
    private String appType;

    /**
     * Rate Limit (requests per second)
     */
    @NotNull(message = "限流配置不能为空")
    @Min(value = 1, message = "限流值至少为 1")
    private Integer rateLimit;

    /**
     * IP Whitelist (JSON array string)
     */
    private String ipWhitelist;

    /**
     * Expiration Time
     */
    private LocalDateTime expireTime;
}
