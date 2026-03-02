package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.ImportExportTaskDTO;
import com.ljwx.platform.app.dto.ImportExportTaskQueryDTO;
import com.ljwx.platform.app.service.ImportExportService;
import com.ljwx.platform.app.vo.ImportExportTaskVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Import/Export Controller
 *
 * @author LJWX Platform
 * @since Phase 46
 */
@RestController
@RequestMapping("/api/v1/import-export")
@RequiredArgsConstructor
public class ImportExportController {

    private final ImportExportService importExportService;

    /**
     * Import data
     */
    @PreAuthorize("hasAuthority('system:importExport:import')")
    @PostMapping("/import")
    public Result<Long> importData(@Valid @RequestBody ImportExportTaskDTO dto) {
        Long taskId = importExportService.createImportTask(dto);
        return Result.ok(taskId);
    }

    /**
     * Export data
     */
    @PreAuthorize("hasAuthority('system:importExport:export')")
    @PostMapping("/export")
    public Result<Long> exportData(@Valid @RequestBody ImportExportTaskDTO dto) {
        Long taskId = importExportService.createExportTask(dto);
        return Result.ok(taskId);
    }

    /**
     * Get task by ID
     */
    @PreAuthorize("hasAuthority('system:importExport:query')")
    @GetMapping("/tasks/{id}")
    public Result<ImportExportTaskVO> getTask(@PathVariable Long id) {
        ImportExportTaskVO task = importExportService.getTaskById(id);
        return Result.ok(task);
    }

    /**
     * List tasks with pagination
     */
    @PreAuthorize("hasAuthority('system:importExport:list')")
    @GetMapping("/tasks")
    public Result<PageResult<ImportExportTaskVO>> listTasks(ImportExportTaskQueryDTO query) {
        PageResult<ImportExportTaskVO> result = importExportService.listTasks(query);
        return Result.ok(result);
    }
}
