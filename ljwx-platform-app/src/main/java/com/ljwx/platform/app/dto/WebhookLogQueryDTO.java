package com.ljwx.platform.app.dto;

import lombok.Data;

/**
 * Webhook Log Query DTO
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Data
public class WebhookLogQueryDTO {

    /**
     * Webhook ID
     */
    private Long webhookId;

    /**
     * Event Type
     */
    private String eventType;

    /**
     * Status: SUCCESS / FAILURE
     */
    private String status;

    /**
     * Page number (default: 1)
     */
    private Integer pageNum = 1;

    /**
     * Page size (default: 10)
     */
    private Integer pageSize = 10;
}
