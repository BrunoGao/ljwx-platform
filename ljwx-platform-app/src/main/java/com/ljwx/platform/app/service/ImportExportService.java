package com.ljwx.platform.app.service;

import com.ljwx.platform.app.dto.ImportExportTaskDTO;
import com.ljwx.platform.app.dto.ImportExportTaskQueryDTO;
import com.ljwx.platform.app.infra.mapper.ImportExportTaskMapper;
import com.ljwx.platform.app.vo.ImportExportTaskVO;
import com.ljwx.platform.core.domain.ImportExportTask;
import com.ljwx.platform.web.exception.BusinessException;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.scheduling.annotation.Async;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.LinkedHashMap;
import java.util.Map;
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
    private final JdbcTemplate jdbcTemplate;

    private static final Path EXPORT_BASE_DIR = Paths.get(
            System.getProperty("java.io.tmpdir"), "ljwx-platform", "exports");
    private static final Path IMPORT_BASE_DIR = Paths.get(
            System.getProperty("java.io.tmpdir"), "ljwx-platform", "imports");

    /**
     * Create import task
     */
    @Transactional
    public Long createImportTask(ImportExportTaskDTO dto) {
        if (dto.getFile() == null || dto.getFile().isEmpty()) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "导入必须上传文件");
        }

        ImportExportTask task = new ImportExportTask();
        task.setId(idGenerator.nextId());
        task.setTaskType("IMPORT");
        task.setBusinessType(dto.getBusinessType());
        task.setFileName(dto.getFileName());
        task.setStatus("PENDING");
        task.setTotalCount(0);
        task.setSuccessCount(0);
        task.setFailureCount(0);
        task.setFileUrl(storeImportFile(task.getId(), dto).toString());

        importExportTaskMapper.insert(task);
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

            ImportExportTask task = importExportTaskMapper.selectById(taskId);
            task.setStatus("PROCESSING");
            importExportTaskMapper.updateById(task);
            task = importExportTaskMapper.selectById(taskId);
            failTask(task, "当前版本未配置业务导入解析器，导入任务已拒绝执行");
        } catch (Exception e) {
            log.error("Import task failed: {}", taskId, e);
            ImportExportTask task = importExportTaskMapper.selectById(taskId);
            if (task != null) {
                failTask(task, e.getMessage());
            }
        }
    }

    /**
     * Process export task asynchronously
     */
    @Async
    protected void processExportTaskAsync(Long taskId) {
        try {
            log.info("Starting export task processing: {}", taskId);

            ImportExportTask task = importExportTaskMapper.selectById(taskId);
            task.setStatus("PROCESSING");
            importExportTaskMapper.updateById(task);
            task = importExportTaskMapper.selectById(taskId);

            ExportDataset dataset = buildExportDataset(task.getBusinessType());
            Path exportFile = writeCsv(task.getId(), task.getFileName(), dataset);

            task.setStatus("SUCCESS");
            task.setTotalCount(dataset.rows().size());
            task.setSuccessCount(dataset.rows().size());
            task.setFailureCount(0);
            task.setFileUrl(exportFile.toUri().toString());
            importExportTaskMapper.updateById(task);

            log.info("Export task completed: {}", taskId);
        } catch (Exception e) {
            log.error("Export task failed: {}", taskId, e);

            ImportExportTask task = importExportTaskMapper.selectById(taskId);
            if (task != null) {
                failTask(task, e.getMessage());
            }
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

    private Path storeImportFile(Long taskId, ImportExportTaskDTO dto) {
        try {
            Files.createDirectories(IMPORT_BASE_DIR);
            Path filePath = IMPORT_BASE_DIR.resolve(taskId + "-" + sanitizeFileName(dto.getFileName()));
            dto.getFile().transferTo(filePath);
            return filePath;
        } catch (IOException e) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "导入文件保存失败");
        }
    }

    private ExportDataset buildExportDataset(String businessType) {
        return switch (businessType) {
            case "USER" -> exportQuery(
                    List.of("id", "username", "nickname", "email", "phone", "status", "created_time"),
                    "SELECT id, username, nickname, email, phone, status, created_time " +
                            "FROM sys_user WHERE deleted = FALSE ORDER BY created_time DESC");
            case "ROLE" -> exportQuery(
                    List.of("id", "name", "code", "status", "created_time"),
                    "SELECT id, name, code, status, created_time " +
                            "FROM sys_role WHERE deleted = FALSE ORDER BY created_time DESC");
            case "DEPT" -> exportQuery(
                    List.of("id", "name", "parent_id", "sort", "status", "created_time"),
                    "SELECT id, name, parent_id, sort, status, created_time " +
                            "FROM sys_dept WHERE deleted = FALSE ORDER BY sort ASC, id ASC");
            case "MENU" -> exportQuery(
                    List.of("id", "name", "parent_id", "path", "component", "permission", "sort", "visible"),
                    "SELECT id, name, parent_id, path, component, permission, sort, visible " +
                            "FROM sys_menu WHERE deleted = FALSE ORDER BY sort ASC, id ASC");
            default -> throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED,
                    "不支持的导出业务类型: " + businessType);
        };
    }

    private ExportDataset exportQuery(List<String> headers, String sql) {
        List<Map<String, Object>> rows = jdbcTemplate.query(
                sql,
                (rs, rowNum) -> {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (String header : headers) {
                        row.put(header, rs.getObject(header));
                    }
                    return row;
                });
        return new ExportDataset(headers, rows);
    }

    private Path writeCsv(Long taskId, String originalFileName, ExportDataset dataset) {
        try {
            Files.createDirectories(EXPORT_BASE_DIR);
            Path filePath = EXPORT_BASE_DIR.resolve(taskId + "-" + normalizeExportFileName(originalFileName));
            try (BufferedWriter writer = Files.newBufferedWriter(filePath, StandardCharsets.UTF_8)) {
                writer.write(String.join(",", dataset.headers()));
                writer.newLine();
                for (Map<String, Object> row : dataset.rows()) {
                    writer.write(dataset.headers().stream()
                            .map(header -> csvValue(row.get(header)))
                            .collect(Collectors.joining(",")));
                    writer.newLine();
                }
            }
            return filePath;
        } catch (IOException e) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "导出文件生成失败");
        }
    }

    private void failTask(ImportExportTask task, String errorMessage) {
        task.setStatus("FAILURE");
        task.setTotalCount(0);
        task.setSuccessCount(0);
        task.setFailureCount(0);
        task.setErrorMessage(errorMessage);
        importExportTaskMapper.updateById(task);
    }

    private String normalizeExportFileName(String originalFileName) {
        String baseName = sanitizeFileName(originalFileName);
        if (baseName.endsWith(".csv")) {
            return baseName;
        }
        int dotIndex = baseName.lastIndexOf('.');
        if (dotIndex > 0) {
            baseName = baseName.substring(0, dotIndex);
        }
        return baseName + ".csv";
    }

    private String sanitizeFileName(String originalFileName) {
        return originalFileName.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    private String csvValue(Object value) {
        String text = value == null ? "" : String.valueOf(value);
        return "\"" + text.replace("\"", "\"\"") + "\"";
    }

    private record ExportDataset(List<String> headers, List<Map<String, Object>> rows) {
    }
}
