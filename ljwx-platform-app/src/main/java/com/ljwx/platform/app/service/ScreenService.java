package com.ljwx.platform.app.service;

import com.ljwx.platform.app.appservice.OnlineUserAppService;
import com.ljwx.platform.app.vo.screen.ScreenOverviewVO;
import com.ljwx.platform.app.vo.screen.ScreenRealtimeVO;
import com.ljwx.platform.app.vo.screen.ScreenRecentOperationVO;
import com.ljwx.platform.app.vo.screen.ScreenStatItemVO;
import com.ljwx.platform.app.vo.screen.ScreenTrendItemVO;
import com.ljwx.platform.app.vo.screen.ScreenTrendVO;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Screen service.
 */
@Service
@RequiredArgsConstructor
public class ScreenService {

    private static final int OVERVIEW_LIMIT = 5;
    private static final int TREND_DAYS = 7;
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm:ss");

    private final JdbcTemplate jdbcTemplate;
    private final OnlineUserAppService onlineUserAppService;

    public ScreenOverviewVO getOverview() {
        ScreenOverviewVO overview = new ScreenOverviewVO();
        overview.setTotalUsers(queryLong("SELECT COUNT(*) FROM sys_user WHERE deleted = FALSE"));
        overview.setTodayUsers(queryLong(
                "SELECT COUNT(*) FROM sys_user WHERE deleted = FALSE " +
                        "AND created_time >= CURRENT_DATE AND created_time < CURRENT_DATE + INTERVAL '1 day'"));
        overview.setTotalTenants(queryLong("SELECT COUNT(*) FROM sys_tenant WHERE deleted = FALSE"));
        overview.setTodayLoginCount(queryLong(
                "SELECT COUNT(*) FROM sys_login_log WHERE deleted = FALSE AND status = 1 " +
                        "AND login_time >= CURRENT_DATE AND login_time < CURRENT_DATE + INTERVAL '1 day'"));
        overview.setTenantUserDistribution(loadTenantUserDistribution());
        overview.setRoleDistribution(loadRoleDistribution());
        overview.setUserStatusDistribution(loadUserStatusDistribution());
        overview.setRecentOperations(loadRecentOperations());
        return overview;
    }

    public ScreenRealtimeVO getRealtime() {
        ScreenRealtimeVO realtime = new ScreenRealtimeVO();
        realtime.setOnlineUsers((long) onlineUserAppService.listOnlineUsers().size());
        realtime.setQps(loadRecentQps());

        Runtime runtime = Runtime.getRuntime();
        double cpuUsage = 0D;
        double memoryUsage = 0D;
        java.lang.management.OperatingSystemMXBean osBean =
                java.lang.management.ManagementFactory.getOperatingSystemMXBean();
        if (osBean instanceof com.sun.management.OperatingSystemMXBean sunOsBean) {
            double cpuLoad = sunOsBean.getCpuLoad();
            if (cpuLoad >= 0) {
                cpuUsage = round(cpuLoad * 100D);
            }

            long totalMemory = sunOsBean.getTotalMemorySize();
            long freeMemory = sunOsBean.getFreeMemorySize();
            if (totalMemory > 0) {
                memoryUsage = round((double) (totalMemory - freeMemory) * 100D / totalMemory);
            }
        } else {
            long totalMemory = runtime.maxMemory();
            long usedMemory = runtime.totalMemory() - runtime.freeMemory();
            if (totalMemory > 0) {
                memoryUsage = round((double) usedMemory * 100D / totalMemory);
            }
        }

        realtime.setCpuUsage(cpuUsage);
        realtime.setMemoryUsage(memoryUsage);
        realtime.setTimestamp(OffsetDateTime.now());
        return realtime;
    }

    public ScreenTrendVO getTrend() {
        ScreenTrendVO trend = new ScreenTrendVO();
        trend.setUserTrend(loadDailyTrend(
                "SELECT CAST(created_time AS DATE) AS stat_date, COUNT(*)::BIGINT AS metric_value " +
                        "FROM sys_user WHERE deleted = FALSE AND created_time >= CURRENT_DATE - INTERVAL '6 days' " +
                        "GROUP BY CAST(created_time AS DATE)"));
        trend.setLoginTrend(loadDailyTrend(
                "SELECT CAST(login_time AS DATE) AS stat_date, COUNT(*)::BIGINT AS metric_value " +
                        "FROM sys_login_log WHERE deleted = FALSE AND status = 1 " +
                        "AND login_time >= CURRENT_DATE - INTERVAL '6 days' " +
                        "GROUP BY CAST(login_time AS DATE)"));
        return trend;
    }

    private List<ScreenStatItemVO> loadTenantUserDistribution() {
        return jdbcTemplate.query(
                "SELECT t.name AS label, COUNT(u.id)::BIGINT AS metric_value " +
                        "FROM sys_tenant t " +
                        "LEFT JOIN sys_user u ON u.tenant_id = t.id AND u.deleted = FALSE " +
                        "WHERE t.deleted = FALSE " +
                        "GROUP BY t.id, t.name " +
                        "ORDER BY metric_value DESC, t.id ASC " +
                        "LIMIT ?",
                (rs, rowNum) -> new ScreenStatItemVO(rs.getString("label"), rs.getLong("metric_value")),
                OVERVIEW_LIMIT);
    }

    private List<ScreenStatItemVO> loadRoleDistribution() {
        return jdbcTemplate.query(
                "SELECT r.name AS label, COUNT(ur.user_id)::BIGINT AS metric_value " +
                        "FROM sys_role r " +
                        "LEFT JOIN sys_user_role ur ON ur.role_id = r.id AND ur.deleted = FALSE " +
                        "WHERE r.deleted = FALSE AND r.status = 1 " +
                        "GROUP BY r.id, r.name " +
                        "ORDER BY metric_value DESC, r.id ASC " +
                        "LIMIT ?",
                (rs, rowNum) -> new ScreenStatItemVO(rs.getString("label"), rs.getLong("metric_value")),
                OVERVIEW_LIMIT);
    }

    private List<ScreenStatItemVO> loadUserStatusDistribution() {
        long enabledUsers = queryLong("SELECT COUNT(*) FROM sys_user WHERE deleted = FALSE AND status = 1");
        long disabledUsers = queryLong("SELECT COUNT(*) FROM sys_user WHERE deleted = FALSE AND status = 0");
        long activeUsers = queryLong(
                "SELECT COUNT(DISTINCT username) FROM sys_login_log " +
                        "WHERE deleted = FALSE AND status = 1 AND login_time >= CURRENT_DATE - INTERVAL '29 days'");
        long inactiveUsers = Math.max(enabledUsers - activeUsers, 0L);

        List<ScreenStatItemVO> distribution = new ArrayList<>();
        distribution.add(new ScreenStatItemVO("活跃", activeUsers));
        distribution.add(new ScreenStatItemVO("非活跃", inactiveUsers));
        distribution.add(new ScreenStatItemVO("禁用", disabledUsers));
        return distribution;
    }

    private List<ScreenRecentOperationVO> loadRecentOperations() {
        return jdbcTemplate.query(
                "SELECT COALESCE(NULLIF(operator_name, ''), 'system') AS username, " +
                        "COALESCE(NULLIF(title, ''), request_method || ' ' || request_url) AS action, " +
                        "created_time AS operation_time " +
                        "FROM sys_operation_log " +
                        "WHERE deleted = FALSE " +
                        "ORDER BY created_time DESC " +
                        "LIMIT 10",
                (rs, rowNum) -> {
                    ScreenRecentOperationVO operation = new ScreenRecentOperationVO();
                    operation.setUsername(rs.getString("username"));
                    operation.setAction(rs.getString("action"));
                    operation.setTime(rs.getTimestamp("operation_time")
                            .toLocalDateTime()
                            .toLocalTime()
                            .format(TIME_FORMATTER));
                    return operation;
                });
    }

    private Double loadRecentQps() {
        Long requestsLastMinute = queryLong(
                "SELECT COUNT(*) FROM sys_operation_log " +
                        "WHERE deleted = FALSE AND created_time >= CURRENT_TIMESTAMP - INTERVAL '1 minute'");
        return round(requestsLastMinute / 60D);
    }

    private List<ScreenTrendItemVO> loadDailyTrend(String sql) {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
        Map<LocalDate, Long> values = new HashMap<>();
        for (Map<String, Object> row : rows) {
            LocalDate date = extractDate(row.get("stat_date"));
            if (date != null) {
                values.put(date, ((Number) row.get("metric_value")).longValue());
            }
        }

        LocalDate today = LocalDate.now();
        List<ScreenTrendItemVO> items = new ArrayList<>(TREND_DAYS);
        for (int i = TREND_DAYS - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            items.add(new ScreenTrendItemVO(date, values.getOrDefault(date, 0L)));
        }
        return items;
    }

    private LocalDate extractDate(Object value) {
        if (value instanceof Date date) {
            return date.toLocalDate();
        }
        if (value instanceof Timestamp timestamp) {
            return timestamp.toLocalDateTime().toLocalDate();
        }
        if (value instanceof LocalDate localDate) {
            return localDate;
        }
        return null;
    }

    private Long queryLong(String sql) {
        Long value = jdbcTemplate.queryForObject(sql, Long.class);
        return value == null ? 0L : value;
    }

    private Double round(double value) {
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP).doubleValue();
    }
}
