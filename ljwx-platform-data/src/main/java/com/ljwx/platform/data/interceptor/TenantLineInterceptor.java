package com.ljwx.platform.data.interceptor;

import com.ljwx.platform.core.context.CurrentTenantHolder;
import lombok.RequiredArgsConstructor;
import org.apache.ibatis.cache.CacheKey;
import org.apache.ibatis.executor.Executor;
import org.apache.ibatis.mapping.BoundSql;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.mapping.ParameterMapping;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Signature;
import org.apache.ibatis.session.ResultHandler;
import org.apache.ibatis.session.RowBounds;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Properties;

/**
 * MyBatis interceptor that automatically appends {@code WHERE tenant_id = ?}
 * to every SELECT query, implementing row-level multi-tenant isolation.
 *
 * <h3>Mechanism</h3>
 * <ol>
 *   <li>Intercepts the 4-arg {@code Executor.query} before MyBatis prepares the statement.</li>
 *   <li>Reads the current tenant ID from {@link CurrentTenantHolder} (a {@code core} interface).</li>
 *   <li>Rewrites the SQL, injecting {@code AND tenant_id = {id}} (Long, no SQL-injection risk).</li>
 *   <li>Creates a new {@link BoundSql} with the modified SQL and calls the 6-arg
 *       {@code executor.query} — which is NOT intercepted by this class, preventing
 *       infinite recursion.</li>
 * </ol>
 *
 * <h3>DAG Compliance</h3>
 * <p>Depends only on {@code core} interfaces. The actual {@code CurrentTenantHolder}
 * implementation is injected at runtime by the {@code security} module.
 * {@link ObjectProvider} enables safe lazy resolution, returning {@code null} if
 * no implementation is registered (e.g., unauthenticated batch jobs — query proceeds
 * without tenant filter in that case).
 *
 * <h3>SQL Edge Cases</h3>
 * <ul>
 *   <li>Plain SELECT — appends {@code WHERE tenant_id = N}</li>
 *   <li>SELECT with WHERE — appends {@code AND tenant_id = N} before ORDER BY / LIMIT etc.</li>
 *   <li>UNION queries — wraps the entire query in a subquery</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
@Intercepts({
    @Signature(
        type   = Executor.class,
        method = "query",
        args   = {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class}
    )
})
public class TenantLineInterceptor implements Interceptor {

    /**
     * Tenant line handler that determines whether to apply tenant filtering.
     * Handles super admin logic (tenant_id = 0 skips filtering).
     */
    private final TenantLineHandler tenantLineHandler;

    @Override
    @SuppressWarnings({"rawtypes", "unchecked"})
    public Object intercept(Invocation invocation) throws Throwable {
        MappedStatement ms            = (MappedStatement) invocation.getArgs()[0];
        Object          parameter     = invocation.getArgs()[1];
        RowBounds       rowBounds     = (RowBounds) invocation.getArgs()[2];
        ResultHandler   resultHandler = (ResultHandler) invocation.getArgs()[3];

        Long tenantId = tenantLineHandler.getTenantId();
        if (tenantId == null) {
            // No tenant context (unauthenticated / system operation / super admin) — skip filter
            return invocation.proceed();
        }

        Executor executor        = (Executor) invocation.getTarget();
        BoundSql originalBoundSql = ms.getBoundSql(parameter);
        String   originalSql     = originalBoundSql.getSql().trim();
        String   tenantSql       = injectTenantCondition(originalSql, tenantId);

        // Build a new BoundSql with the rewritten SQL
        BoundSql tenantBoundSql = new BoundSql(
                ms.getConfiguration(),
                tenantSql,
                originalBoundSql.getParameterMappings(),
                originalBoundSql.getParameterObject()
        );
        copyAdditionalParameters(originalBoundSql, tenantBoundSql);

        // Call the 6-arg query — not intercepted by this class, no infinite loop
        CacheKey cacheKey = executor.createCacheKey(ms, parameter, rowBounds, tenantBoundSql);
        return executor.query(ms, parameter, rowBounds, resultHandler, cacheKey, tenantBoundSql);
    }

    /**
     * Rewrites the SQL to include a tenant_id condition.
     *
     * <p>The tenant ID is a {@code Long}, so embedding it directly is safe (no injection).
     */
    private String injectTenantCondition(String sql, Long tenantId) {
        String upperSql        = sql.toUpperCase();
        String appendCondition = " AND tenant_id = " + tenantId;

        // UNION queries: wrap the entire query in a subquery
        if (upperSql.contains(" UNION ")) {
            return "SELECT * FROM (" + sql + ") _ljwx_t WHERE tenant_id = " + tenantId;
        }

        if (upperSql.contains(" WHERE ")) {
            // Existing WHERE clause — inject before ORDER BY / GROUP BY / HAVING / LIMIT etc.
            int afterWhere  = upperSql.indexOf(" WHERE ") + 7; // advance past " WHERE "
            int insertPos   = findTailClauseStart(upperSql, afterWhere);
            if (insertPos > 0) {
                return sql.substring(0, insertPos) + appendCondition + sql.substring(insertPos);
            }
            return sql + appendCondition;
        } else {
            // No WHERE clause — inject a new WHERE before ORDER BY / GROUP BY etc.
            int insertPos = findTailClauseStart(upperSql, 0);
            if (insertPos > 0) {
                return sql.substring(0, insertPos)
                        + " WHERE tenant_id = " + tenantId
                        + sql.substring(insertPos);
            }
            return sql + " WHERE tenant_id = " + tenantId;
        }
    }

    /**
     * Returns the position of the earliest tail clause keyword (ORDER BY, GROUP BY,
     * HAVING, LIMIT, OFFSET, FETCH) after {@code startFrom}, or {@code -1} if none.
     */
    private int findTailClauseStart(String upperSql, int startFrom) {
        String[] tailClauses = {
            " ORDER BY ", " GROUP BY ", " HAVING ",
            " LIMIT ", " OFFSET ", " FETCH "
        };
        int earliest = -1;
        for (String clause : tailClauses) {
            int pos = upperSql.indexOf(clause, startFrom);
            if (pos > 0 && (earliest < 0 || pos < earliest)) {
                earliest = pos;
            }
        }
        return earliest;
    }

    /**
     * Copies additional parameters (dynamic-SQL context variables such as
     * {@code _parameter} and {@code _databaseId}) from the original BoundSql
     * to the tenant-aware BoundSql.
     */
    private void copyAdditionalParameters(BoundSql source, BoundSql target) {
        List<ParameterMapping> mappings = source.getParameterMappings();
        for (ParameterMapping mapping : mappings) {
            String prop = mapping.getProperty();
            if (source.hasAdditionalParameter(prop)) {
                target.setAdditionalParameter(prop, source.getAdditionalParameter(prop));
            }
        }
    }

    /**
     * Resolves the current tenant ID from the security context.
     * Returns {@code null} when no authenticated tenant is present.
     *
     * @deprecated Use {@link TenantLineHandler#getTenantId()} instead
     */
    @Deprecated
    private Long resolveTenantId() {
        return tenantLineHandler.getTenantId();
    }

    @Override
    public void setProperties(Properties properties) {
        // No configurable properties for this interceptor
    }
}
