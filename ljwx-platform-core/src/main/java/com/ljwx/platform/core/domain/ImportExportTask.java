package com.ljwx.platform.core.domain;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Import/Export Task Entity
 *
 * @author LJWX Platform
 * @since Phase 46
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_import_export_task")
public class ImportExportTask extends BaseEntity {

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
}
