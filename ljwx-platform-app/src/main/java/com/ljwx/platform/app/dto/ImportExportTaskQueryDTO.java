package com.ljwx.platform.app.dto;

import lombok.Data;

/**
 * Import/Export Task Query DTO
 *
 * @author LJWX Platform
 * @since Phase 46
 */
@Data
public class ImportExportTaskQueryDTO {

    /**
     * Task type: IMPORT / EXPORT
     */
    private String taskType;

    /**
     * Business type: USER / ROLE / DEPT / MENU
     */
    private String businessType;

    /**
     * Status: PENDING / PROCESSING / SUCCESS / FAILURE
     */
    private String status;

    /**
     * Page number (1-based)
     */
    private Integer pageNum = 1;

    /**
     * Page size
     */
    private Integer pageSize = 10;
}
