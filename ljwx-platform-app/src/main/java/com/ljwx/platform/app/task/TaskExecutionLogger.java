package com.ljwx.platform.app.task;

import com.ljwx.platform.app.domain.entity.TaskExecutionLog;
import com.ljwx.platform.app.infra.mapper.TaskExecutionLogMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.InetAddress;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * 任务执行日志记录器
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TaskExecutionLogger {

    private final TaskExecutionLogMapper taskExecutionLogMapper;
    private final SnowflakeIdGenerator snowflakeIdGenerator;

    /**
     * 记录任务开始
     *
     * @param taskName   任务名称
     * @param taskGroup  任务分组
     * @param taskParams 任务参数
     * @return 日志 ID
     */
    public Long logStart(String taskName, String taskGroup, String taskParams) {
        try {
            TaskExecutionLog logEntity = TaskExecutionLog.builder()
                    .id(snowflakeIdGenerator.nextId())
                    .taskName(taskName)
                    .taskGroup(taskGroup)
                    .taskParams(taskParams)
                    .status("RUNNING")
                    .startTime(LocalDateTime.now())
                    .serverIp(getServerIp())
                    .serverName(getServerName())
                    .build();

            taskExecutionLogMapper.insert(logEntity);
            return logEntity.getId();
        } catch (Exception e) {
            log.error("记录任务开始失败: taskName={}, taskGroup={}", taskName, taskGroup, e);
            return null;
        }
    }

    /**
     * 记录任务成功
     *
     * @param logId  日志 ID
     * @param result 执行结果
     */
    public void logSuccess(Long logId, String result) {
        if (logId == null) {
            return;
        }

        try {
            TaskExecutionLog logEntity = taskExecutionLogMapper.selectById(logId);
            if (logEntity == null) {
                log.warn("任务日志不存在: logId={}", logId);
                return;
            }

            LocalDateTime endTime = LocalDateTime.now();
            logEntity.setStatus("SUCCESS");
            logEntity.setEndTime(endTime);
            logEntity.setDuration(calculateDuration(logEntity.getStartTime(), endTime));
            logEntity.setResult(result);

            taskExecutionLogMapper.updateById(logEntity);
        } catch (Exception e) {
            log.error("记录任务成功失败: logId={}", logId, e);
        }
    }

    /**
     * 记录任务失败
     *
     * @param logId     日志 ID
     * @param exception 异常
     */
    public void logFailure(Long logId, Exception exception) {
        if (logId == null) {
            return;
        }

        try {
            TaskExecutionLog logEntity = taskExecutionLogMapper.selectById(logId);
            if (logEntity == null) {
                log.warn("任务日志不存在: logId={}", logId);
                return;
            }

            LocalDateTime endTime = LocalDateTime.now();
            logEntity.setStatus("FAILURE");
            logEntity.setEndTime(endTime);
            logEntity.setDuration(calculateDuration(logEntity.getStartTime(), endTime));
            logEntity.setErrorMessage(exception.getMessage());
            logEntity.setErrorStack(getStackTrace(exception));

            taskExecutionLogMapper.updateById(logEntity);
        } catch (Exception e) {
            log.error("记录任务失败失败: logId={}", logId, e);
        }
    }

    /**
     * 计算执行耗时
     */
    private int calculateDuration(LocalDateTime start, LocalDateTime end) {
        return (int) Duration.between(start, end).toMillis();
    }

    /**
     * 获取异常堆栈
     */
    private String getStackTrace(Exception exception) {
        StringWriter sw = new StringWriter();
        exception.printStackTrace(new PrintWriter(sw));
        String stackTrace = sw.toString();
        // 限制堆栈长度，避免过长
        return stackTrace.length() > 4000 ? stackTrace.substring(0, 4000) : stackTrace;
    }

    /**
     * 获取服务器 IP
     */
    private String getServerIp() {
        try {
            return InetAddress.getLocalHost().getHostAddress();
        } catch (Exception e) {
            return "unknown";
        }
    }

    /**
     * 获取服务器名称
     */
    private String getServerName() {
        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            return "unknown";
        }
    }
}
