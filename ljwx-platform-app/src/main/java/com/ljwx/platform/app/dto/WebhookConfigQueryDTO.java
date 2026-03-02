package com.ljwx.platform.app.dto;

import lombok.Data;

/**
 * Webhook Configuration Query DTO
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Data
public class WebhookConfigQueryDTO {

    /**
     * Webhook Name (fuzzy search)
     */
    private String webhookName;

    /**
     * Status: ENABLED / DISABLED
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
