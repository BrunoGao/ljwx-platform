package com.ljwx.platform.data.interceptor;

import com.ljwx.platform.data.context.DataScopeContext;
import com.ljwx.platform.data.context.DataScopeContext.DataScopeInfo;
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
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Properties;
import java.util.stream.Collectors;

/**
 * 数据权限 MyBatis 拦截器。
 *
 * <p>从 {@link DataScopeContext}（ThreadLocal）读取当前用户的数据权限范围，
 * 自动追加 SQL 条件实现行级数据隔离。
 *
 * <h3>DAG 合规</h3>
 * <p>本类仅依赖 {@code data} 模块内的 {@link DataScopeContext}，
 * 不得引用 security 模块的任何类（DAG 规则：data 不依赖 security）。
 * data_scope 由 web 模块的拦截器通过 ThreadLocal 传入。
 *
 * <h3>数据权限范围</h3>
 * <ul>
 *   <li>SCOPE_ALL (0)：不追加条件</li>
 *   <li>SCOPE_TENANT (1)：不追加条件（TenantLineInterceptor 已处理）</li>
 *   <li>SCOPE_DEPT_AND_CHILD (2)：AND dept_id IN (id1, id2, ...)</li>
 *   <li>SCOPE_DEPT (3)：AND dept_id IN (id)</li>
 *   <li>SCOPE_SELF (4)：AND created_by = userId</li>
 * </ul>
 */
@Component
@Intercepts({
    @Signature(
        type   = Executor.class,
        method = "query",
        args   = {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class}
    )
})
public class DataScopeInterceptor implements Interceptor {

    @Override
    @SuppressWarnings({"rawtypes", "unchecked"})
    public Object intercept(Invocation invocation) throws Throwable {
        DataScopeInfo scopeInfo = DataScopeContext.get();
        if (scopeInfo == null) {
            return invocation.proceed();
        }

        int scope = scopeInfo.getScope();
        if (scope == DataScopeContext.SCOPE_ALL || scope == DataScopeContext.SCOPE_TENANT) {
            return invocation.proceed();
        }

        MappedStatement ms            = (MappedStatement) invocation.getArgs()[0];
        Object          parameter     = invocation.getArgs()[1];
        RowBounds       rowBounds     = (RowBounds) invocation.getArgs()[2];
        ResultHandler   resultHandler = (ResultHandler) invocation.getArgs()[3];

        String extraCondition = buildCondition(scopeInfo);
        if (extraCondition == null) {
            return invocation.proceed();
        }

        Executor executor         = (Executor) invocation.getTarget();
        BoundSql originalBoundSql = ms.getBoundSql(parameter);
        String   rewrittenSql     = injectCondition(originalBoundSql.getSql().trim(), extraCondition);

        BoundSql newBoundSql = new BoundSql(
                ms.getConfiguration(),
                rewrittenSql,
                originalBoundSql.getParameterMappings(),
                originalBoundSql.getParameterObject()
        );
        copyAdditionalParameters(originalBoundSql, newBoundSql);

        CacheKey cacheKey = executor.createCacheKey(ms, parameter, rowBounds, newBoundSql);
        return executor.query(ms, parameter, rowBounds, resultHandler, cacheKey, newBoundSql);
    }

    private String buildCondition(DataScopeInfo info) {
        int scope = info.getScope();
        if (scope == DataScopeContext.SCOPE_SELF) {
            if (info.getUserId() == null) return null;
            return "created_by = " + info.getUserId();
        }
        // SCOPE_DEPT or SCOPE_DEPT_AND_CHILD
        List<Long> deptIds = info.getDeptIds();
        if (deptIds.isEmpty()) return null;
        String ids = deptIds.stream().map(String::valueOf).collect(Collectors.joining(", "));
        return "dept_id IN (" + ids + ")";
    }

    private String injectCondition(String sql, String condition) {
        String upper = sql.toUpperCase();
        String andCondition = " AND " + condition;
        if (upper.contains(" WHERE ")) {
            int afterWhere = upper.indexOf(" WHERE ") + 7;
            int insertPos  = findTailClause(upper, afterWhere);
            if (insertPos > 0) {
                return sql.substring(0, insertPos) + andCondition + sql.substring(insertPos);
            }
            return sql + andCondition;
        } else {
            int insertPos = findTailClause(upper, 0);
            if (insertPos > 0) {
                return sql.substring(0, insertPos) + " WHERE " + condition + sql.substring(insertPos);
            }
            return sql + " WHERE " + condition;
        }
    }

    private int findTailClause(String upper, int from) {
        String[] clauses = {" ORDER BY ", " GROUP BY ", " HAVING ", " LIMIT ", " OFFSET ", " FETCH "};
        int earliest = -1;
        for (String c : clauses) {
            int pos = upper.indexOf(c, from);
            if (pos > 0 && (earliest < 0 || pos < earliest)) {
                earliest = pos;
            }
        }
        return earliest;
    }

    private void copyAdditionalParameters(BoundSql source, BoundSql target) {
        for (ParameterMapping mapping : source.getParameterMappings()) {
            String prop = mapping.getProperty();
            if (source.hasAdditionalParameter(prop)) {
                target.setAdditionalParameter(prop, source.getAdditionalParameter(prop));
            }
        }
    }

    @Override
    public void setProperties(Properties properties) {
        // No configurable properties
    }
}
