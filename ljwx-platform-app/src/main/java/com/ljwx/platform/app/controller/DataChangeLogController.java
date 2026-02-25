package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.DataChangeLogAppService;
import com.ljwx.platform.app.domain.vo.DataChangeLogVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

/**
 * 数据变更审计日志 Controller。
 *
 * <p>路由：
 * <ul>
 *   <li>GET /api/v1/data-change-logs — system:audit:list — 查询数据变更日志</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/data-change-logs")
@RequiredArgsConstructor
public class DataChangeLogController {

    private final DataChangeLogAppService dataChangeLogAppService;

    /**
     * 查询数据变更日志列表（分页）。
     *
     * @param tableName 表名（可选）
     * @param recordId  记录ID（可选）
     * @param startTime 开始时间（可选）
     * @param endTime   结束时间（可选）
     * @param pageNum   页码（默认 1）
     * @param pageSize  每页大小（默认 10）
     * @return 分页结果
     */
    @PreAuthorize("hasAuthority('system:audit:list')")
    @GetMapping
    public Result<PageResult<DataChangeLogVO>> list(
        @RequestParam(required = false) String tableName,
        @RequestParam(required = false) Long recordId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime,
        @RequestParam(defaultValue = "1") int pageNum,
        @RequestParam(defaultValue = "10") int pageSize
    ) {
        return Result.ok(dataChangeLogAppService.listDataChangeLogs(
            tableName, recordId, startTime, endTime, pageNum, pageSize
        ));
    }
}
