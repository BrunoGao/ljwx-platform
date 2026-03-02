package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Webhook Configuration VO
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Data
public class WebhookConfigVO {

    /**
     * Primary Key
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
     * Event Types
     */
    private List<String> eventTypes;

    /**
     * Status: ENABLED / DISABLED
     */
    private String status;

    /**
     * Max Retry Count
     */
    private Integer retryCount;

    /**
     * Timeout in seconds
     */
    private Integer timeoutSeconds;

    /**
     * Created Time
     */
    private LocalDateTime createdTime;

    /**
     * Updated Time
     */
    private LocalDateTime updatedTime;
}
