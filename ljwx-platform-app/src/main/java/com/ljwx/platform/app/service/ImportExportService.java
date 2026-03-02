package com.ljwx.platform.app.service;

import com.ljwx.platform.app.dto.ImportExportTaskDTO;
import com.ljwx.platform.app.dto.ImportExportTaskQueryDTO;
import com.ljwx.platform.app.infra.mapper.ImportExportTaskMapper;
import com.ljwx.platform.app.vo.ImportExportTaskVO;
import com.ljwx.platform.app.domain.entity.ImportExportTask;
import com.ljwx.platform.web.exception.BusinessException;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Import/Export Service
 *
 * @author LJWX Platform
 * @since Phase 46
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImportExportService {

    private final ImportExportTaskMapper importExportTaskMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * Create import task
     */
    @Transactional
    public Long createImportTask(ImportExportTaskDTO dto) {
        ImportExportTask task = new ImportExportTask();
        task.setId(idGenerator.nextId());
        task.setTaskType("IMPORT");
        task.setBusinessType(dto.getBusinessType());
        task.setFileName(dto.getFileName());
        task.setStatus("PENDING");
        task.setTotalCount(0);
        task.setSuccessCount(0);
        task.setFailureCount(0);

        importExportTaskMapper.insert(task);

        // Trigger async processing
        processImportTaskAsync(task.getId());

        return task.getId();
    }

    /**
     * Create export task
     */
    @Transactional
    public Long createExportTask(ImportExportTaskDTO dto) {
        ImportExportTask task = new ImportExportTask();
        task.setId(idGenerator.nextId());
        task.setTaskType("EXPORT");
        task.setBusinessType(dto.getBusinessType());
        task.setFileName(dto.getFileName());
        task.setStatus("PENDING");
        task.setTotalCount(0);
        task.setSuccessCount(0);
        task.setFailureCount(0);

        importExportTaskMapper.insert(task);

        // Trigger async processing
        processExportTaskAsync(task.getId());

        return task.getId();
    }

    /**
     * Get task by ID
     */
    public ImportExportTaskVO getTaskById(Long id) {
        ImportExportTask task = importExportTaskMapper.selectById(id);
        if (task == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "任务不存在");
        }
        return convertToVO(task);
    }

    /**
     * List tasks with pagination
     */
    public PageResult<ImportExportTaskVO> listTasks(ImportExportTaskQueryDTO query) {
        ImportExportTask queryEntity = new ImportExportTask();
        // Set query parameters based on DTO
        List<ImportExportTask> tasks = importExportTaskMapper.selectList(queryEntity);
        long total = importExportTaskMapper.count(queryEntity);

        List<ImportExportTaskVO> voList = tasks.stream()
                .map(this::convertToVO)
                .collect(Collectors.toList());

        return new PageResult<>(voList, total);
    }

    /**
     * Process import task asynchronously
     */
    @Async
    protected void processImportTaskAsync(Long taskId) {
        try {
            log.info("Starting import task processing: {}", taskId);

            // Update status to PROCESSING
            ImportExportTask task = importExportTaskMapper.selectById(taskId);
            task.setStatus("PROCESSING");
            importExportTaskMapper.updateById(task);

            // TODO: Implement actual import logic
            // 1. Read file from MinIO
            // 2. Parse Excel
            // 3. Validate data
            // 4. Import to database
            // 5. Update progress

            // Simulate processing
            Thread.sleep(2000);

            // Update status to SUCCESS
            task.setStatus("SUCCESS");
            task.setTotalCount(100);
            task.setSuccessCount(100);
            task.setFailureCount(0);
            importExportTaskMapper.updateById(task);

            log.info("Import task completed: {}", taskId);
        } catch (Exception e) {
            log.error("Import task failed: {}", taskId, e);

            // Update status to FAILURE
            ImportExportTask task = importExportTaskMapper.selectById(taskId);
            task.setStatus("FAILURE");
            task.setErrorMessage(e.getMessage());
            importExportTaskMapper.updateById(task);
        }
    }

    /**
     * Process export task asynchronously
     */
    @Async
    protected void processExportTaskAsync(Long taskId) {
        try {
            log.info("Starting export task processing: {}", taskId);

            // Update status to PROCESSING
            ImportExportTask task = importExportTaskMapper.selectById(taskId);
            task.setStatus("PROCESSING");
            importExportTaskMapper.updateById(task);

            // TODO: Implement actual export logic
            // 1. Query data from database
            // 2. Generate Excel
            // 3. Upload to MinIO
            // 4. Update file URL

            // Simulate processing
            Thread.sleep(2000);

            // Update status to SUCCESS
            task.setStatus("SUCCESS");
            task.setTotalCount(100);
            task.setSuccessCount(100);
            task.setFailureCount(0);
            task.setFileUrl("http://minio.example.com/exports/file.xlsx");
            importExportTaskMapper.updateById(task);

            log.info("Export task completed: {}", taskId);
        } catch (Exception e) {
            log.error("Export task failed: {}", taskId, e);

            // Update status to FAILURE
            ImportExportTask task = importExportTaskMapper.selectById(taskId);
            task.setStatus("FAILURE");
            task.setErrorMessage(e.getMessage());
            importExportTaskMapper.updateById(task);
        }
    }

    /**
     * Convert entity to VO
     */
    private ImportExportTaskVO convertToVO(ImportExportTask task) {
        ImportExportTaskVO vo = new ImportExportTaskVO();
        BeanUtils.copyProperties(task, vo);
        return vo;
    }
}
