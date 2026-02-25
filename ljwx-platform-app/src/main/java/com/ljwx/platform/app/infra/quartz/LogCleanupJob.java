package com.ljwx.platform.app.infra.quartz;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.quartz.DisallowConcurrentExecution;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 日志清理定时任务。
 *
 * <p>Cron: {@code 0 0 2 * * ?}（每天凌晨 2 点）
 *
 * <p>功能：
 * <ul>
 *   <li>读取 sys_config 中 {@code system.log.retention.days}（默认 90 天）</li>
 *   <li>清理 sys_operation_log、sys_login_log、sys_frontend_error 中超过保留期的记录</li>
 *   <li>每次最多删除 1000 条（分批删除，避免长事务）</li>
 * </ul>
 *
 * <p>使用 {@link DisallowConcurrentExecution} 防止并发执行。
 */
@Slf4j
@Component
@RequiredArgsConstructor
@DisallowConcurrentExecution
public class LogCleanupJob implements Job {

    private final JdbcTemplate jdbcTemplate;

    /** 默认保留天数 */
    private static final int DEFAULT_RETENTION_DAYS = 90;

    /** 每批删除的最大记录数 */
    private static final int BATCH_SIZE = 1000;

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        try {
            log.info("LogCleanupJob started");

            // 读取配置的保留天数
            int retentionDays = getRetentionDays();
            LocalDateTime cutoffTime = LocalDateTime.now().minusDays(retentionDays);

            log.info("Cleaning logs older than {} (retention: {} days)", cutoffTime, retentionDays);

            // 清理各类日志
            int operationLogDeleted = cleanupTable("sys_operation_log", cutoffTime);
            int loginLogDeleted = cleanupTable("sys_login_log", cutoffTime);
            int frontendErrorDeleted = cleanupTable("sys_frontend_error", cutoffTime);

            log.info("LogCleanupJob completed: operation_log={}, login_log={}, frontend_error={}",
                operationLogDeleted, loginLogDeleted, frontendErrorDeleted);

        } catch (Exception e) {
            log.error("LogCleanupJob failed: {}", e.getMessage(), e);
            throw new JobExecutionException(e);
        }
    }

    /**
     * 从 sys_config 读取日志保留天数。
     */
    private int getRetentionDays() {
        try {
            String sql = "SELECT config_value FROM sys_config WHERE config_key = ? AND deleted = FALSE";
            String value = jdbcTemplate.queryForObject(sql, String.class, "system.log.retention.days");
            return value != null ? Integer.parseInt(value) : DEFAULT_RETENTION_DAYS;
        } catch (Exception e) {
            log.warn("Failed to read retention days from sys_config, using default: {}", DEFAULT_RETENTION_DAYS);
            return DEFAULT_RETENTION_DAYS;
        }
    }

    /**
     * 清理指定表中超过保留期的记录。
     *
     * @param tableName  表名
     * @param cutoffTime 截止时间
     * @return 删除的记录数
     */
    private int cleanupTable(String tableName, LocalDateTime cutoffTime) {
        int totalDeleted = 0;
        int batchDeleted;

        do {
            String sql = String.format(
                "DELETE FROM %s WHERE id IN (SELECT id FROM %s WHERE created_time < ? AND deleted = FALSE LIMIT ?)",
                tableName, tableName
            );
            batchDeleted = jdbcTemplate.update(sql, cutoffTime, BATCH_SIZE);
            totalDeleted += batchDeleted;

            if (batchDeleted > 0) {
                log.debug("Deleted {} records from {}", batchDeleted, tableName);
            }
        } while (batchDeleted == BATCH_SIZE);

        return totalDeleted;
    }
}
