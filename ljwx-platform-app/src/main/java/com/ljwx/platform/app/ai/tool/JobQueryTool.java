package com.ljwx.platform.app.ai.tool;

import com.ljwx.platform.app.domain.entity.SysJob;
import com.ljwx.platform.app.domain.entity.TaskExecutionLog;
import com.ljwx.platform.app.infra.mapper.SysJobMapper;
import com.ljwx.platform.app.infra.mapper.TaskExecutionLogMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 任务查询工具 - 提供定时任务查询
 *
 * @author LJWX Platform
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JobQueryTool {

    private final SysJobMapper sysJobMapper;
    private final TaskExecutionLogMapper taskExecutionLogMapper;

    /**
     * 列出定时任务及状态
     * 权限约束：仅 system:job:list
     *
     * @return 定时任务列表
     */
    public Map<String, Object> listScheduledJobs() {
        List<SysJob> jobs = sysJobMapper.selectList(new SysJob());
        List<Map<String, Object>> jobSummaries = jobs.stream()
                .map(job -> Map.<String, Object>of(
                        "id", job.getId(),
                        "jobName", job.getJobName(),
                        "jobGroup", job.getJobGroup() == null ? "" : job.getJobGroup(),
                        "cronExpression", job.getCronExpression() == null ? "" : job.getCronExpression(),
                        "status", job.getStatus() == null ? 0 : job.getStatus(),
                        "description", job.getDescription() == null ? "" : job.getDescription()))
                .toList();
        return Map.of(
                "total", jobSummaries.size(),
                "jobs", jobSummaries
        );
    }

    /**
     * 获取任务最近执行日志
     * 权限约束：仅 system:taskLog:list
     *
     * @param jobId 任务 ID
     * @param limit 限制条数
     * @return 任务执行日志
     */
    public Map<String, Object> getJobLogs(Long jobId, Integer limit) {
        if (jobId == null) {
            return Map.of("total", 0, "logs", List.of());
        }

        SysJob job = sysJobMapper.selectById(jobId);
        if (job == null) {
            return Map.of("total", 0, "logs", List.of(), "message", "任务不存在");
        }

        TaskExecutionLog query = new TaskExecutionLog();
        query.setTaskName(job.getJobName());
        query.setTaskGroup(job.getJobGroup());
        List<TaskExecutionLog> logs = taskExecutionLogMapper.selectList(query);
        int max = limit == null || limit <= 0 ? 10 : limit;

        List<Map<String, Object>> logSummaries = new ArrayList<>();
        for (TaskExecutionLog log : logs.stream().limit(max).toList()) {
            logSummaries.add(Map.of(
                    "id", log.getId(),
                    "taskName", log.getTaskName(),
                    "taskGroup", log.getTaskGroup() == null ? "" : log.getTaskGroup(),
                    "status", log.getStatus() == null ? "" : log.getStatus(),
                    "startTime", log.getStartTime(),
                    "endTime", log.getEndTime(),
                    "duration", log.getDuration() == null ? 0 : log.getDuration(),
                    "errorMessage", log.getErrorMessage() == null ? "" : log.getErrorMessage()
            ));
        }

        return Map.of(
                "total", logs.size(),
                "logs", logSummaries
        );
    }
}
