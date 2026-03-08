package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.OperationLogAppService;
import com.ljwx.platform.app.domain.dto.OperationLogQueryDTO;
import com.ljwx.platform.app.domain.entity.SysOperationLog;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 操作日志 Controller。
 * 权限按 spec/03-api.md §Logs 路由定义。
 *
 * <p>路由：
 * <ul>
 *   <li>GET  /api/logs/operation  — log:read   — 操作日志列表</li>
 *   <li>POST /api/logs/export     — log:export — 导出日志</li>
 * </ul>
 */
@RestController
@RequestMapping({"/api/v1", "/api"})
@RequiredArgsConstructor
public class OperationLogController {

    private final OperationLogAppService operationLogAppService;

    /**
     * 查询操作日志列表（分页）。
     */
    @PreAuthorize("hasAuthority('log:read')")
    @GetMapping("/logs/operation")
    public Result<PageResult<SysOperationLog>> listOperationLogs(OperationLogQueryDTO query) {
        return Result.ok(operationLogAppService.listOperationLogs(query));
    }

    @PreAuthorize("hasAuthority('log:read')")
    @GetMapping("/logs/operation/{id}")
    public Result<SysOperationLog> getOperationLog(@PathVariable Long id) {
        return Result.ok(operationLogAppService.getOperationLogById(id));
    }

    /**
     * 导出操作日志（返回 JSON 列表，客户端可自行处理为 Excel）。
     */
    @PreAuthorize("hasAuthority('log:export')")
    @PostMapping("/logs/export")
    public Result<List<SysOperationLog>> exportLogs(OperationLogQueryDTO query) {
        return Result.ok(operationLogAppService.exportLogs(query));
    }

    @PreAuthorize("hasAuthority('log:write')")
    @DeleteMapping("/logs/operation/{id}")
    public Result<Void> deleteOperationLog(@PathVariable Long id) {
        operationLogAppService.deleteOperationLog(id);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('log:write')")
    @DeleteMapping("/logs/operation/clean")
    public Result<Integer> cleanOperationLogs() {
        return Result.ok(operationLogAppService.cleanOperationLogs());
    }
}
