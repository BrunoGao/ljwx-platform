package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * Open API Application Entity
 *
 * @author LJWX Platform
 * @since Phase 47
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class OpenApp extends BaseEntity {

    /**
     * Primary Key (Snowflake ID)
     */
    private Long id;

    /**
     * Application Key (UUID format, auto-generated)
     */
    private String appKey;

    /**
     * Application Secret (HMAC signature, encrypted storage)
     */
    private String appSecret;

    /**
     * Application Name
     */
    private String appName;

    /**
     * Application Type: INTERNAL / EXTERNAL
     */
    private String appType;

    /**
     * Status: ENABLED / DISABLED
     */
    private String status;

    /**
     * Rate Limit (requests per second)
     */
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
