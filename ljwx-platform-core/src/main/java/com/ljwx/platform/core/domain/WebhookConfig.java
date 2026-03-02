package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Webhook Configuration Entity
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class WebhookConfig extends BaseEntity {

    /**
     * Primary Key (Snowflake ID)
     */
    private Long id;

    /**
     * Webhook Name
     */
    private String webhookName;

    /**
     * Webhook URL
     */
    private String webhookUrl;

    /**
     * Subscribed Event Types (JSON array string)
     */
    private String eventTypes;

    /**
     * Signature Secret Key
     */
    private String secretKey;

    /**
     * Status: ENABLED / DISABLED
     */
    private String status;

    /**
     * Maximum Retry Count
     */
    private Integer retryCount;

    /**
     * Timeout in Seconds
     */
    private Integer timeoutSeconds;
}
