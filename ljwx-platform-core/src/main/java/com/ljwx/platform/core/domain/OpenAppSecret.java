package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * Open API Secret Entity
 *
 * @author LJWX Platform
 * @since Phase 48
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class OpenAppSecret extends BaseEntity {

    /**
     * Primary Key (Snowflake ID)
     */
    private Long id;

    /**
     * Application ID
     */
    private Long appId;

    /**
     * Encrypted Secret Key (256-bit, Base64 encoded)
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
}
