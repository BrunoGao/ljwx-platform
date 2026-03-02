package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

/**
 * Import/Export Task DTO
 *
 * @author LJWX Platform
 * @since Phase 46
 */
@Data
public class ImportExportTaskDTO {

    /**
     * Task type: IMPORT / EXPORT
     */
    @NotBlank(message = "任务类型不能为空")
    private String taskType;

    /**
     * Business type: USER / ROLE / DEPT / MENU
     */
    @NotBlank(message = "业务类型不能为空")
    private String businessType;

    /**
     * File name
     */
    @NotBlank(message = "文件名不能为空")
    private String fileName;

    /**
     * Import file (for import tasks)
     */
    private MultipartFile file;
}
