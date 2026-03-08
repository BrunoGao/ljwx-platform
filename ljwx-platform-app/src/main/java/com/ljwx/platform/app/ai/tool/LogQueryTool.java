package com.ljwx.platform.app.ai.tool;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 日志查询工具 - 提供操作日志和登录日志查询
 *
 * @author LJWX Platform
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LogQueryTool {

    private final JdbcTemplate jdbcTemplate;

    /**
     * 查询操作日志
     * 权限约束：仅 system:operlog:list
     *
     * @param startTime 开始时间
     * @param endTime   结束时间
     * @param userId    用户 ID（可选）
     * @param module    模块名称（可选）
     * @param limit     限制条数
     * @return 操作日志列表
     */
    public Map<String, Object> queryOperationLogs(LocalDateTime startTime, LocalDateTime endTime,
                                                    Long userId, String module, Integer limit) {
        StringBuilder where = new StringBuilder(" WHERE deleted = FALSE");
        List<Object> params = new ArrayList<>();

        if (startTime != null) {
            where.append(" AND created_time >= ?");
            params.add(Timestamp.valueOf(startTime));
        }
        if (endTime != null) {
            where.append(" AND created_time <= ?");
            params.add(Timestamp.valueOf(endTime));
        }
        if (userId != null) {
            where.append(" AND operator_id = ?");
            params.add(userId);
        }
        if (module != null && !module.isBlank()) {
            where.append(" AND title ILIKE ?");
            params.add("%" + module.trim() + "%");
        }

        Long total = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_operation_log" + where,
                params.toArray(),
                Long.class
        );

        int max = limit == null || limit <= 0 ? 10 : limit;
        List<Object> logParams = new ArrayList<>(params);
        logParams.add(max);
        List<Map<String, Object>> logs = jdbcTemplate.query(
                "SELECT id, title, operator_id, operator_name, status, request_method, request_url, cost_time, created_time " +
                        "FROM sys_operation_log" + where + " ORDER BY created_time DESC LIMIT ?",
                logParams.toArray(),
                (rs, rowNum) -> Map.<String, Object>of(
                        "id", rs.getLong("id"),
                        "title", rs.getString("title") == null ? "" : rs.getString("title"),
                        "operatorId", rs.getLong("operator_id"),
                        "operatorName", rs.getString("operator_name") == null ? "" : rs.getString("operator_name"),
                        "status", rs.getInt("status"),
                        "requestMethod", rs.getString("request_method") == null ? "" : rs.getString("request_method"),
                        "requestUrl", rs.getString("request_url") == null ? "" : rs.getString("request_url"),
                        "costTime", rs.getLong("cost_time"),
                        "createdTime", rs.getTimestamp("created_time").toLocalDateTime()
                )
        );

        return Map.of(
                "total", total == null ? 0L : total,
                "logs", logs
        );
    }

    /**
     * 查询登录日志
     * 权限约束：仅 system:loginlog:list
     *
     * @param startTime 开始时间
     * @param endTime   结束时间
     * @param userId    用户 ID（可选）
     * @param limit     限制条数
     * @return 登录日志列表
     */
    public Map<String, Object> queryLoginLogs(LocalDateTime startTime, LocalDateTime endTime,
                                               Long userId, Integer limit) {
        String fromClause = " FROM sys_login_log l LEFT JOIN sys_user u ON u.username = l.username AND u.deleted = FALSE";
        StringBuilder where = new StringBuilder(" WHERE l.deleted = FALSE");
        List<Object> params = new ArrayList<>();

        if (startTime != null) {
            where.append(" AND l.login_time >= ?");
            params.add(Timestamp.valueOf(startTime));
        }
        if (endTime != null) {
            where.append(" AND l.login_time <= ?");
            params.add(Timestamp.valueOf(endTime));
        }
        if (userId != null) {
            where.append(" AND u.id = ?");
            params.add(userId);
        }

        Long total = jdbcTemplate.queryForObject(
                "SELECT COUNT(*)" + fromClause + where,
                params.toArray(),
                Long.class
        );

        int max = limit == null || limit <= 0 ? 10 : limit;
        List<Object> logParams = new ArrayList<>(params);
        logParams.add(max);
        List<Map<String, Object>> logs = jdbcTemplate.query(
                "SELECT l.id, l.username, l.status, l.message, l.ip_address, l.login_time" +
                        fromClause + where + " ORDER BY l.login_time DESC LIMIT ?",
                logParams.toArray(),
                (rs, rowNum) -> Map.<String, Object>of(
                        "id", rs.getLong("id"),
                        "username", rs.getString("username") == null ? "" : rs.getString("username"),
                        "status", rs.getInt("status"),
                        "message", rs.getString("message") == null ? "" : rs.getString("message"),
                        "ipAddress", rs.getString("ip_address") == null ? "" : rs.getString("ip_address"),
                        "loginTime", rs.getTimestamp("login_time").toLocalDateTime()
                )
        );

        return Map.of(
                "total", total == null ? 0L : total,
                "logs", logs
        );
    }
}
