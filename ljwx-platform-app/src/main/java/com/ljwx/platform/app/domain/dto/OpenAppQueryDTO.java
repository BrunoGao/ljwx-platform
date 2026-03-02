package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * Open API Application Query DTO
 *
 * @author LJWX Platform
 * @since Phase 47
 */
@Data
public class OpenAppQueryDTO {

    /**
     * Application Name (fuzzy search)
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
     * Page number (starting from 1)
     */
    private Integer pageNum = 1;

    /**
     * Page size
     */
    private Integer pageSize = 10;
}
