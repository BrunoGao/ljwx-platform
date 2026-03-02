package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Webhook Log Entity
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class WebhookLog extends BaseEntity {

    /**
     * Primary Key (Snowflake ID)
     */
    private Long id;

    /**
     * Webhook Config ID (FK → sys_webhook_config.id)
     */
    private Long webhookId;

    /**
     * Event Type
     */
    private String eventType;

    /**
     * Event Data (JSON)
     */
    private String eventData;

    /**
     * Request URL
     */
    private String requestUrl;

    /**
     * Request Headers (JSON)
     */
    private String requestHeaders;

    /**
     * Request Body
     */
    private String requestBody;

    /**
     * HTTP Response Status Code
     */
    private Integer responseStatus;

    /**
     * Response Body
     */
    private String responseBody;

    /**
     * Retry Times
     */
    private Integer retryTimes;

    /**
     * Status: SUCCESS / FAILURE
     */
    private String status;

    /**
     * Error Message
     */
    private String errorMessage;
}
