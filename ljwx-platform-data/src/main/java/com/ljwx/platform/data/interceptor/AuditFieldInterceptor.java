package com.ljwx.platform.data.interceptor;

import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.entity.BaseEntity;
import lombok.RequiredArgsConstructor;
import org.apache.ibatis.executor.Executor;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.mapping.SqlCommandType;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Signature;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Properties;

/**
 * MyBatis interceptor that auto-fills audit fields on INSERT and UPDATE.
 *
 * <p>On <b>INSERT</b>: sets {@code createdBy}, {@code createdTime}, {@code updatedBy},
 * {@code updatedTime} — only if the field is currently {@code null}.
 *
 * <p>On <b>UPDATE</b>: always overwrites {@code updatedBy} and {@code updatedTime}.
 *
 * <p>The current user ID is obtained from {@link CurrentUserHolder} (a {@code core}
 * interface). The concrete implementation ({@code SecurityContextUserHolder}) is
 * registered at runtime by the {@code security} module — this class has <b>no direct
 * dependency on {@code security}</b>, satisfying the DAG rule:
 * {@code core ← {security, data}}.
 *
 * <p>{@link ObjectProvider} is used for lazy, optional injection: if no
 * {@code CurrentUserHolder} bean is available (e.g., batch/system operations),
 * {@code 0L} is used as a safe fallback — matching the SQL {@code DEFAULT 0}.
 */
@Component
@RequiredArgsConstructor
@Intercepts({
    @Signature(
        type   = Executor.class,
        method = "update",
        args   = {MappedStatement.class, Object.class}
    )
})
public class AuditFieldInterceptor implements Interceptor {

    /**
     * Optional provider for the current-user context.
     * Returns {@code null} when the security module has not registered an implementation.
     */
    private final ObjectProvider<CurrentUserHolder> userHolderProvider;

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        MappedStatement ms        = (MappedStatement) invocation.getArgs()[0];
        Object          parameter = invocation.getArgs()[1];
        SqlCommandType  sqlType   = ms.getSqlCommandType();

        if (parameter instanceof BaseEntity entity) {
            LocalDateTime now    = LocalDateTime.now();
            Long          userId = resolveUserId();

            if (sqlType == SqlCommandType.INSERT) {
                // Only set if not already provided by the caller
                if (entity.getCreatedBy()   == null) { entity.setCreatedBy(userId);   }
                if (entity.getCreatedTime() == null) { entity.setCreatedTime(now);    }
                if (entity.getUpdatedBy()   == null) { entity.setUpdatedBy(userId);   }
                if (entity.getUpdatedTime() == null) { entity.setUpdatedTime(now);    }
            } else if (sqlType == SqlCommandType.UPDATE) {
                // Always refresh on UPDATE
                entity.setUpdatedBy(userId);
                entity.setUpdatedTime(now);
            }
        }

        return invocation.proceed();
    }

    /**
     * Resolves the current user ID from the security context.
     * Returns {@code 0L} when no authenticated user is present.
     */
    private Long resolveUserId() {
        try {
            CurrentUserHolder holder = userHolderProvider.getIfAvailable();
            if (holder != null) {
                Long id = holder.getUserId();
                return id != null ? id : 0L;
            }
        } catch (Exception ignored) {
            // Context not available — safe to ignore (e.g., startup, batch jobs)
        }
        return 0L;
    }

    @Override
    public void setProperties(Properties properties) {
        // No configurable properties for this interceptor
    }
}
