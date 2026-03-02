package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * Open API Application VO
 *
 * @author LJWX Platform
 * @since Phase 47
 */
@Data
public class OpenAppVO {

    /**
     * Primary Key
     */
    private Long id;

    /**
     * Application Key
     */
    private String appKey;

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

    /**
     * Created Time
     */
    private LocalDateTime createdTime;
}
