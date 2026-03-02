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

    /** 自定义数据范围（从 sys_role_data_scope 表读取） */
    public static final int SCOPE_CUSTOM = 5;

    private static final ThreadLocal<DataScopeInfo> HOLDER = new ThreadLocal<>();

    private DataScopeContext() {}

    /**
     * 设置数据范围上下文（旧版本，兼容保留）。
     */
    public static void set(DataScopeInfo info) {
        HOLDER.set(info);
    }

    /**
     * 设置数据范围上下文（Phase 44 新增）。
     *
     * @param userId  用户 ID
     * @param deptId  部门 ID
     * @param roleIds 角色 ID 列表
     */
    public static void set(Long userId, Long deptId, List<Long> roleIds) {
        HOLDER.set(new DataScopeInfo(userId, deptId, roleIds));
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
        private final Long deptId;
        private final List<Long> roleIds;
        private final List<Long> deptIds;

        /**
         * 旧版本构造函数（兼容保留）。
         */
        public DataScopeInfo(int scope, Long userId, List<Long> deptIds) {
            this.scope   = scope;
            this.userId  = userId;
            this.deptId  = null;
            this.roleIds = Collections.emptyList();
            this.deptIds = deptIds != null ? deptIds : Collections.emptyList();
        }

        /**
         * Phase 44 新增构造函数。
         */
        public DataScopeInfo(Long userId, Long deptId, List<Long> roleIds) {
            this.scope   = SCOPE_CUSTOM;  // 默认使用 CUSTOM 模式
            this.userId  = userId;
            this.deptId  = deptId;
            this.roleIds = roleIds != null ? roleIds : Collections.emptyList();
            this.deptIds = Collections.emptyList();
        }

        public int getScope()          { return scope; }
        public Long getUserId()        { return userId; }
        public Long getDeptId()        { return deptId; }
        public List<Long> getRoleIds() { return roleIds; }
        public List<Long> getDeptIds() { return deptIds; }
    }
}
