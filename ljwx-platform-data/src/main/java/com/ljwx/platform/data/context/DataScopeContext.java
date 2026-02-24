package com.ljwx.platform.data.context;

import java.util.Collections;
import java.util.List;

/**
 * 数据权限上下文（ThreadLocal）。
 *
 * <p>由 web 模块的拦截器在每次请求前设置，DataScopeInterceptor 读取后追加 SQL 条件。
 * 请求结束后必须调用 {@link #clear()} 防止内存泄漏。
 *
 * <p>DAG 合规：本类仅依赖 JDK，不 import security 包。
 */
public final class DataScopeContext {

    /** 全部数据（不追加额外条件） */
    public static final int SCOPE_ALL = 0;

    /** 本租户数据（TenantLineInterceptor 已处理，无需额外条件） */
    public static final int SCOPE_TENANT = 1;

    /** 本部门及下级部门 */
    public static final int SCOPE_DEPT_AND_CHILD = 2;

    /** 仅本部门 */
    public static final int SCOPE_DEPT = 3;

    /** 仅本人（created_by = userId） */
    public static final int SCOPE_SELF = 4;

    private static final ThreadLocal<DataScopeInfo> HOLDER = new ThreadLocal<>();

    private DataScopeContext() {}

    public static void set(DataScopeInfo info) {
        HOLDER.set(info);
    }

    public static DataScopeInfo get() {
        return HOLDER.get();
    }

    public static void clear() {
        HOLDER.remove();
    }

    /**
     * 数据权限信息载体。
     */
    public static class DataScopeInfo {

        private final int scope;
        private final Long userId;
        private final List<Long> deptIds;

        public DataScopeInfo(int scope, Long userId, List<Long> deptIds) {
            this.scope   = scope;
            this.userId  = userId;
            this.deptIds = deptIds != null ? deptIds : Collections.emptyList();
        }

        public int getScope()          { return scope; }
        public Long getUserId()        { return userId; }
        public List<Long> getDeptIds() { return deptIds; }
    }
}
