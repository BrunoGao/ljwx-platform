package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * Open API Secret VO
 *
 * @author LJWX Platform
 * @since Phase 48
 */
@Data
public class OpenAppSecretVO {

    /**
     * Primary Key
     */
    private Long id;

    /**
     * Application ID
     */
    private Long appId;

    /**
     * Secret Key (plain text only on creation, masked otherwise)
     */
    private String secretKey;

    /**
     * Secret Version Number
     */
    private Integer secretVersion;

    /**
     * Status: ACTIVE / EXPIRED
     */
    private String status;

    /**
     * Expiration Time
     */
    private LocalDateTime expireTime;

    /**
     * Creation Time
     */
    private LocalDateTime createdTime;

    /**
     * Update Time
     */
    private LocalDateTime updatedTime;
}
