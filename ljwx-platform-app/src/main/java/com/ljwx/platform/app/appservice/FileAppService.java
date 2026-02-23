package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.FileQueryDTO;
import com.ljwx.platform.app.domain.entity.SysFile;
import com.ljwx.platform.app.infra.mapper.SysFileMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 文件管理应用服务。
 *
 * <p>文件命名：Snowflake ID + 原始后缀。
 * 存储路径：{@code {basePath}/tenant_{tenantId}/{yyyy}/{MM}/{dd}/{snowflakeId}.{ext}}
 * <p>限制：上传最大 50 MB，后缀白名单见 {@link #ALLOWED_EXTENSIONS}。
 * tenant_id 由 TenantLineInterceptor 自动注入到 DB，文件路径使用 CurrentTenantHolder 获取。
 */
@Service
@RequiredArgsConstructor
public class FileAppService {

    /** 允许上传的文件后缀白名单（小写，不含点号） */
    private static final Set<String> ALLOWED_EXTENSIONS = new HashSet<>(Arrays.asList(
            "jpg", "jpeg", "png", "gif", "webp", "svg",
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
            "txt", "csv",
            "zip", "rar", "7z",
            "mp4", "mp3"
    ));

    /** 文件最大大小：50 MB */
    private static final long MAX_FILE_SIZE = 50L * 1024 * 1024;

    private static final DateTimeFormatter YEAR_FMT  = DateTimeFormatter.ofPattern("yyyy");
    private static final DateTimeFormatter MONTH_FMT = DateTimeFormatter.ofPattern("MM");
    private static final DateTimeFormatter DAY_FMT   = DateTimeFormatter.ofPattern("dd");

    private final SysFileMapper fileMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder currentTenantHolder;

    @Value("${ljwx.file.base-path:./uploads}")
    private String basePath;

    /**
     * 分页查询文件列表。
     * TenantLineInterceptor 自动注入 tenant_id，无需手动设置。
     */
    public PageResult<SysFile> listFiles(FileQueryDTO query) {
        List<SysFile> records = fileMapper.selectList(query);
        long total = fileMapper.countList(query);
        return new PageResult<>(records, total);
    }

    /**
     * 上传文件：校验后缀、大小，以 Snowflake ID 命名存盘，并写入元数据。
     *
     * @param multipartFile 上传的文件
     * @return 保存后的文件元数据实体
     */
    @Transactional
    public SysFile uploadFile(MultipartFile multipartFile) throws IOException {
        // 1. 校验文件不为空
        if (multipartFile == null || multipartFile.isEmpty()) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "上传文件不能为空");
        }

        // 2. 校验文件大小（50 MB 上限）
        if (multipartFile.getSize() > MAX_FILE_SIZE) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "文件大小超过限制（最大 50 MB）");
        }

        // 3. 校验文件后缀白名单
        String originalFilename = multipartFile.getOriginalFilename();
        String extension = getExtension(originalFilename);
        if (extension.isEmpty() || !ALLOWED_EXTENSIONS.contains(extension.toLowerCase())) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "不支持的文件类型：" + extension);
        }

        // 4. 生成存储路径：{basePath}/tenant_{tenantId}/{yyyy}/{MM}/{dd}/
        Long tenantId = currentTenantHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        LocalDate today = LocalDate.now();
        String relativeDirPath = "tenant_" + tenantId
                + File.separator + today.format(YEAR_FMT)
                + File.separator + today.format(MONTH_FMT)
                + File.separator + today.format(DAY_FMT);

        File storageDir = new File(basePath, relativeDirPath);
        if (!storageDir.exists() && !storageDir.mkdirs()) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "文件目录创建失败");
        }

        // 5. 以 Snowflake ID 命名
        long fileId = idGenerator.nextId();
        String storedFileName = fileId + "." + extension.toLowerCase();
        String relativeFilePath = relativeDirPath + File.separator + storedFileName;

        File destFile = new File(storageDir, storedFileName);
        multipartFile.transferTo(destFile);

        // 6. 写入元数据（tenant_id 由 TenantLineInterceptor 自动注入，禁止手动设置）
        SysFile sysFile = new SysFile();
        sysFile.setId(fileId);
        sysFile.setFileName(originalFilename != null ? originalFilename : storedFileName);
        sysFile.setFilePath(relativeFilePath);
        sysFile.setFileSize(multipartFile.getSize());
        sysFile.setFileType(extension.toLowerCase());
        sysFile.setContentType(
                StringUtils.hasText(multipartFile.getContentType())
                        ? multipartFile.getContentType()
                        : "application/octet-stream");

        fileMapper.insert(sysFile);
        return sysFile;
    }

    /**
     * 删除文件（软删除元数据，同时删除磁盘文件）。
     *
     * @param id 文件ID
     */
    @Transactional
    public void deleteFile(Long id) {
        SysFile sysFile = fileMapper.selectById(id);
        if (sysFile == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "文件不存在");
        }
        // 删除磁盘文件
        File diskFile = new File(basePath, sysFile.getFilePath());
        if (diskFile.exists()) {
            diskFile.delete();
        }
        // 软删除元数据
        fileMapper.deleteById(id);
    }

    /**
     * 获取文件 Resource 用于下载。
     *
     * @param id 文件ID
     * @return {@link Resource} 指向磁盘文件
     */
    public Resource downloadFile(Long id) {
        SysFile sysFile = fileMapper.selectById(id);
        if (sysFile == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "文件不存在");
        }
        File diskFile = new File(basePath, sysFile.getFilePath());
        if (!diskFile.exists()) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "文件在磁盘上不存在，可能已被清理");
        }
        return new FileSystemResource(diskFile);
    }

    /**
     * 根据文件ID查询元数据（用于下载时获取 Content-Disposition）。
     */
    public SysFile getFileById(Long id) {
        SysFile sysFile = fileMapper.selectById(id);
        if (sysFile == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "文件不存在");
        }
        return sysFile;
    }

    // ── 私有工具方法 ─────────────────────────────────────────────

    /**
     * 从文件名提取后缀（不含点号）。若无后缀则返回空字符串。
     */
    private static String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "";
        }
        return filename.substring(filename.lastIndexOf('.') + 1);
    }
}
