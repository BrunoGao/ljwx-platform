package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * Webhook Log VO
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Data
public class WebhookLogVO {

    /**
     * Primary Key
     */
    private Long id;

    /**
     * Webhook Config ID
     */
    private Long webhookId;

    /**
     * Webhook Name
     */
    private String webhookName;

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

    /**
     * Created Time
     */
    private LocalDateTime createdTime;
}
