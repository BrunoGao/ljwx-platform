package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.FileAppService;
import com.ljwx.platform.app.domain.dto.FileQueryDTO;
import com.ljwx.platform.app.domain.entity.SysFile;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * 文件管理 Controller。
 * 权限按 spec/03-api.md §Files 路由定义。
 *
 * <p>路由：
 * <ul>
 *   <li>GET    /api/files              — file:read   — 文件列表</li>
 *   <li>POST   /api/files/upload       — file:upload — 上传文件</li>
 *   <li>DELETE /api/files/{id}         — file:delete — 删除文件</li>
 *   <li>GET    /api/files/{id}/download — file:read  — 下载文件</li>
 * </ul>
 */
@RestController
@RequestMapping({"/api/v1/files", "/api/files"})
@RequiredArgsConstructor
public class FileController {

    private final FileAppService fileAppService;

    /**
     * 查询文件列表（分页）。
     */
    @PreAuthorize("hasAuthority('file:read')")
    @GetMapping
    public Result<PageResult<SysFile>> list(FileQueryDTO query) {
        return Result.ok(fileAppService.listFiles(query));
    }

    /**
     * 上传文件。校验后缀白名单和 50 MB 大小限制，以 Snowflake ID 命名存盘。
     *
     * @param file 上传的 MultipartFile
     * @return 保存后的文件元数据
     */
    @PreAuthorize("hasAuthority('file:upload')")
    @PostMapping("/upload")
    public Result<SysFile> upload(@RequestParam("file") MultipartFile file) throws IOException {
        return Result.ok(fileAppService.uploadFile(file));
    }

    /**
     * 删除文件（软删除元数据，同时删除磁盘文件）。
     */
    @PreAuthorize("hasAuthority('file:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        fileAppService.deleteFile(id);
        return Result.ok();
    }

    /**
     * 下载文件，返回文件流，设置 Content-Disposition 为原始文件名。
     */
    @PreAuthorize("hasAuthority('file:read')")
    @GetMapping("/{id}/download")
    public ResponseEntity<Resource> download(@PathVariable Long id) {
        SysFile sysFile = fileAppService.getFileById(id);
        Resource resource = fileAppService.downloadFile(id);

        ContentDisposition contentDisposition = ContentDisposition.attachment()
                .filename(sysFile.getFileName(), StandardCharsets.UTF_8)
                .build();

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(sysFile.getContentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, contentDisposition.toString())
                .body(resource);
    }
}
