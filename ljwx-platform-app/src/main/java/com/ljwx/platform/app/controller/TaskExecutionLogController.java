package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.TaskExecutionLogAppService;
import com.ljwx.platform.app.domain.dto.TaskExecutionLogQueryDTO;
import com.ljwx.platform.app.domain.vo.TaskExecutionLogVO;
import com.ljwx.platform.app.domain.vo.TaskLogStatsVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * 任务执行日志控制器
 */
@RestController
@RequestMapping("/api/v1/task-logs")
@RequiredArgsConstructor
public class TaskExecutionLogController {

    private final TaskExecutionLogAppService taskExecutionLogAppService;

    /**
     * 查询任务执行日志列表
     *
     * @param query 查询条件
     * @return 分页结果
     */
    @PreAuthorize("hasAuthority('system:taskLog:list')")
    @GetMapping
    public Result<PageResult<TaskExecutionLogVO>> list(TaskExecutionLogQueryDTO query) {
        return Result.ok(taskExecutionLogAppService.list(query));
    }

    /**
     * 查询任务执行日志详情
     *
     * @param id 日志 ID
     * @return 日志详情
     */
    @PreAuthorize("hasAuthority('system:taskLog:query')")
    @GetMapping("/{id}")
    public Result<TaskExecutionLogVO> getById(@PathVariable Long id) {
        return Result.ok(taskExecutionLogAppService.getById(id));
    }

    /**
     * 删除任务执行日志
     *
     * @param id 日志 ID
     * @return 操作结果
     */
    @PreAuthorize("hasAuthority('system:taskLog:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        taskExecutionLogAppService.delete(id);
        return Result.ok();
    }

    /**
     * 清理历史日志（30 天前）
     *
     * @return 清理数量
     */
    @PreAuthorize("hasAuthority('system:taskLog:clean')")
    @PostMapping("/clean")
    public Result<Integer> cleanOldLogs() {
        return Result.ok(taskExecutionLogAppService.cleanOldLogs());
    }

    /**
     * 获取任务执行统计
     *
     * @return 统计结果
     */
    @PreAuthorize("hasAuthority('system:taskLog:stats')")
    @GetMapping("/stats")
    public Result<TaskLogStatsVO> getStats() {
        return Result.ok(taskExecutionLogAppService.getStats());
    }
}
