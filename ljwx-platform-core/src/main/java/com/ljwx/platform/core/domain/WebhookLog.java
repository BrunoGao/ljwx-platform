package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Webhook Push Log Entity
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
     * Webhook Configuration ID (FK → sys_webhook_config.id)
     */
    private Long webhookId;

    /**
     * Event Type
     */
    private String eventType;

    /**
     * Event Data (JSON string)
     */
    private String eventData;

    /**
     * Request URL
     */
    private String requestUrl;

    /**
     * Request Headers (JSON string)
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
