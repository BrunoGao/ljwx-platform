package com.ljwx.platform.data.interceptor;

import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.data.annotation.AuditChange;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.executor.Executor;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.mapping.SqlCommandType;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Signature;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 数据变更审计拦截器。
 *
 * <p>拦截标注了 {@link AuditChange} 注解的 Mapper 方法，
 * 在 UPDATE / DELETE 操作前后对比数据差异，并异步写入 sys_data_change_log 表。
 *
 * <p>注意：本类在 data 模块，禁止 import security 包（DAG 约束）。
 * tenantId 从 {@link CurrentTenantHolder}（core 接口）获取，
 * userId 从 {@link CurrentUserHolder}（core 接口）获取。
 */
@Slf4j
@Component
@RequiredArgsConstructor
@Intercepts({
    @Signature(
        type   = Executor.class,
        method = "update",
        args   = {MappedStatement.class, Object.class}
    )
})
public class DataChangeInterceptor implements Interceptor {

    private final ObjectProvider<CurrentTenantHolder> tenantHolderProvider;
    private final ObjectProvider<CurrentUserHolder> userHolderProvider;
    private final ObjectProvider<DataSource> dataSourceProvider;
    private final ObjectProvider<SnowflakeIdGenerator> idGeneratorProvider;

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        MappedStatement ms        = (MappedStatement) invocation.getArgs()[0];
        Object          parameter = invocation.getArgs()[1];
        SqlCommandType  sqlType   = ms.getSqlCommandType();

        // 仅处理 UPDATE 和 DELETE
        if (sqlType != SqlCommandType.UPDATE && sqlType != SqlCommandType.DELETE) {
            return invocation.proceed();
        }

        // 检查是否标注了 @AuditChange
        AuditChange annotation = getAuditChangeAnnotation(ms);
        if (annotation == null) {
            return invocation.proceed();
        }

        // 提取记录 ID
        Long recordId = extractRecordId(parameter, annotation.idField());
        if (recordId == null) {
            log.warn("Cannot extract record ID from parameter, skip audit: {}", ms.getId());
            return invocation.proceed();
        }

        // 查询变更前的数据
        Map<String, Object> oldData = queryOldData(
            invocation,
            annotation.tableName(),
            annotation.idField(),
            recordId
        );

        // 执行原操作
        Object result = invocation.proceed();

        // 查询变更后的数据（DELETE 操作则为空）
        Map<String, Object> newData = null;
        if (sqlType == SqlCommandType.UPDATE) {
            newData = queryOldData(
                invocation,
                annotation.tableName(),
                annotation.idField(),
                recordId
            );
        }

        Long tenantId = resolveTenantId();
        Long userId = resolveUserId();

        // 异步记录变更
        recordChangesAsync(
            annotation.tableName(),
            recordId,
            oldData,
            newData,
            sqlType == SqlCommandType.DELETE ? "DELETE" : "UPDATE",
            tenantId,
            userId
        );

        return result;
    }

    /**
     * 获取方法上的 @AuditChange 注解。
     */
    private AuditChange getAuditChangeAnnotation(MappedStatement ms) {
        try {
            String id = ms.getId();
            int lastDot = id.lastIndexOf('.');
            if (lastDot == -1) {
                return null;
            }
            String className = id.substring(0, lastDot);
            String methodName = id.substring(lastDot + 1);

            Class<?> mapperClass = Class.forName(className);
            for (Method method : mapperClass.getDeclaredMethods()) {
                if (method.getName().equals(methodName)) {
                    return method.getAnnotation(AuditChange.class);
                }
            }
        } catch (Exception e) {
            log.warn("Failed to get @AuditChange annotation for {}: {}", ms.getId(), e.getMessage());
        }
        return null;
    }

    /**
     * 从参数中提取记录 ID。
     */
    private Long extractRecordId(Object parameter, String idField) {
        if (parameter == null) {
            return null;
        }
        try {
            if (parameter instanceof Map) {
                Object id = ((Map<?, ?>) parameter).get(idField);
                return id instanceof Long ? (Long) id : null;
            }
            Field field = parameter.getClass().getDeclaredField(idField);
            field.setAccessible(true);
            Object id = field.get(parameter);
            return id instanceof Long ? (Long) id : null;
        } catch (Exception e) {
            log.warn("Failed to extract record ID: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 查询变更前的数据。
     */
    private Map<String, Object> queryOldData(
        Invocation invocation,
        String tableName,
        String idField,
        Long recordId
    ) {
        try {
            Executor executor = (Executor) invocation.getTarget();

            // 使用原生 JDBC 查询（避免触发其他拦截器）
            Connection conn = executor.getTransaction().getConnection();
            String sql = String.format("SELECT * FROM %s WHERE %s = ?", tableName, idField);

            try (var stmt = conn.prepareStatement(sql)) {
                stmt.setLong(1, recordId);
                try (var rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        Map<String, Object> data = new HashMap<>();
                        var metaData = rs.getMetaData();
                        for (int i = 1; i <= metaData.getColumnCount(); i++) {
                            String columnName = metaData.getColumnName(i);
                            Object value = rs.getObject(i);
                            data.put(columnName, value);
                        }
                        return data;
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to query old data: {}", e.getMessage(), e);
        }
        return Collections.emptyMap();
    }

    /**
     * 异步记录变更。
     */
    @Async("logTaskExecutor")
    public void recordChangesAsync(
        String tableName,
        Long recordId,
        Map<String, Object> oldData,
        Map<String, Object> newData,
        String operateType,
        Long tenantId,
        Long userId
    ) {
        try {
            LocalDateTime now = LocalDateTime.now();

            List<Map<String, Object>> changes = new ArrayList<>();

            if ("DELETE".equals(operateType)) {
                // DELETE: 记录所有字段的旧值
                for (Map.Entry<String, Object> entry : oldData.entrySet()) {
                    Map<String, Object> change = new HashMap<>();
                    change.put("table_name", tableName);
                    change.put("record_id", recordId);
                    change.put("field_name", entry.getKey());
                    change.put("old_value", stringifyValue(entry.getValue()));
                    change.put("new_value", "");
                    change.put("operate_type", "DELETE");
                    change.put("tenant_id", tenantId);
                    change.put("created_by", userId);
                    change.put("created_time", now);
                    changes.add(change);
                }
            } else {
                // UPDATE: 仅记录变更的字段
                for (Map.Entry<String, Object> entry : oldData.entrySet()) {
                    String fieldName = entry.getKey();
                    Object oldValue = entry.getValue();
                    Object newValue = newData.get(fieldName);

                    if (!Objects.equals(oldValue, newValue)) {
                        Map<String, Object> change = new HashMap<>();
                        change.put("table_name", tableName);
                        change.put("record_id", recordId);
                        change.put("field_name", fieldName);
                        change.put("old_value", stringifyValue(oldValue));
                        change.put("new_value", stringifyValue(newValue));
                        change.put("operate_type", "UPDATE");
                        change.put("tenant_id", tenantId);
                        change.put("created_by", userId);
                        change.put("created_time", now);
                        changes.add(change);
                    }
                }
            }

            if (!changes.isEmpty()) {
                persistChanges(changes, now, userId);
                log.info("Recorded {} changes for {}.{}", changes.size(), tableName, recordId);
            }
        } catch (Exception e) {
            log.error("Failed to record changes: {}", e.getMessage(), e);
        }
    }

    private void persistChanges(List<Map<String, Object>> changes, LocalDateTime now, Long userId) throws Exception {
        DataSource dataSource = dataSourceProvider.getIfAvailable();
        SnowflakeIdGenerator idGenerator = idGeneratorProvider.getIfAvailable();
        if (dataSource == null || idGenerator == null) {
            log.warn("Data change audit skipped because datasource or id generator is unavailable");
            return;
        }

        String insertSql = "INSERT INTO sys_data_change_log (" +
                "id, table_name, record_id, field_name, old_value, new_value, operate_type, " +
                "tenant_id, created_by, created_time, updated_by, updated_time, deleted, version" +
                ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection connection = dataSource.getConnection();
             var statement = connection.prepareStatement(insertSql)) {
            for (Map<String, Object> change : changes) {
                statement.setLong(1, idGenerator.nextId());
                statement.setString(2, (String) change.get("table_name"));
                statement.setLong(3, (Long) change.get("record_id"));
                statement.setString(4, (String) change.get("field_name"));
                statement.setString(5, (String) change.get("old_value"));
                statement.setString(6, (String) change.get("new_value"));
                statement.setString(7, (String) change.get("operate_type"));
                statement.setLong(8, (Long) change.get("tenant_id"));
                statement.setLong(9, (Long) change.get("created_by"));
                statement.setObject(10, change.get("created_time"));
                statement.setLong(11, userId);
                statement.setObject(12, now);
                statement.setBoolean(13, false);
                statement.setInt(14, 1);
                statement.addBatch();
            }
            statement.executeBatch();
        }
    }

    private String stringifyValue(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    private Long resolveTenantId() {
        try {
            CurrentTenantHolder holder = tenantHolderProvider.getIfAvailable();
            if (holder != null) {
                Long id = holder.getTenantId();
                return id != null ? id : 0L;
            }
        } catch (Exception ignored) {
        }
        return 0L;
    }

    private Long resolveUserId() {
        try {
            CurrentUserHolder holder = userHolderProvider.getIfAvailable();
            if (holder != null) {
                Long id = holder.getUserId();
                return id != null ? id : 0L;
            }
        } catch (Exception ignored) {
        }
        return 0L;
    }

    @Override
    public void setProperties(Properties properties) {
        // No configurable properties
    }
}
