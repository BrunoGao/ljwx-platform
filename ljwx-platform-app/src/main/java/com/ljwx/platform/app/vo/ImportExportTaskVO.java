package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * Import/Export Task VO
 *
 * @author LJWX Platform
 * @since Phase 46
 */
@Data
public class ImportExportTaskVO {

    /**
     * Task ID
     */
    private Long id;

    /**
     * Task type: IMPORT / EXPORT
     */
    private String taskType;

    /**
     * Business type: USER / ROLE / DEPT / MENU
     */
    private String businessType;

    /**
     * File name
     */
    private String fileName;

    /**
     * File URL (MinIO)
     */
    private String fileUrl;

    /**
     * Status: PENDING / PROCESSING / SUCCESS / FAILURE
     */
    private String status;

    /**
     * Total record count
     */
    private Integer totalCount;

    /**
     * Success record count
     */
    private Integer successCount;

    /**
     * Failure record count
     */
    private Integer failureCount;

    /**
     * Error message
     */
    private String errorMessage;

    /**
     * Created time
     */
    private LocalDateTime createdTime;
}
