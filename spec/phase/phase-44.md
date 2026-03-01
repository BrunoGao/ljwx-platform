---
phase: 44
title: "角色-自定义数据范围 (Role Custom Data Scope)"
targets:
  backend: true
  frontend: true
depends_on: [43]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V044__add_role_custom_data_scope.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/RoleDataScope.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/RoleDataScopeMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/RoleDataScopeAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/RoleDataScopeController.java"
  - "ljwx-platform-data/src/main/java/com/ljwx/platform/data/interceptor/DataScopeInterceptor.java"
  - "ljwx-platform-data/src/main/java/com/ljwx/platform/data/context/DataScopeContext.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/DataScopeContextFilter.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/RoleDataScopeUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/RoleDataScopeVO.java"
---
# Phase 44 — 角色-自定义数据范围

| 项目 | 值 |
|-----|---|
| Phase | 44 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-data (拦截器) |
| Feature | L2-D02-F02 |
| 前置依赖 | Phase 43 (租户域名识别) |
| 测试契约 | `spec/tests/phase-44-role-data-scope.tests.yml` |
| 优先级 | 🟡 **P1 - 数据权限完整性** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §角色数据范围表
- `spec/03-api.md` — §角色数据范围 API
- `spec/01-constraints.md` — §审计字段、§数据权限
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 当前系统的数据范围仅支持 5 种固定类型（ALL/DEPT/DEPT_AND_CHILD/SELF/CUSTOM),但 CUSTOM 类型没有实现,无法实现灵活的数据权限控制。

**解决方案**: 实现角色自定义数据范围功能,支持:
1. 角色绑定自定义部门列表
2. DataScopeInterceptor 根据角色数据范围动态拼接 SQL
3. 支持多角色数据范围合并（OR 逻辑）
4. 数据范围缓存（Caffeine L1 + Redis L2）

---

## 数据库契约

### 表结构：sys_role_data_scope

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| role_id | BIGINT | NOT NULL, INDEX | 角色 ID |
| dept_id | BIGINT | NOT NULL, INDEX | 部门 ID |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_role_dept` (tenant_id, role_id, dept_id, deleted) UNIQUE
- `idx_role_id` (role_id)
- `idx_dept_id` (dept_id)
- `idx_tenant_id` (tenant_id)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V044__add_role_custom_data_scope.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|---------|
| GET | /api/v1/roles/{roleId}/data-scope | system:role:query | — | Result<RoleDataScopeVO> | 查询角色数据范围 |
| PUT | /api/v1/roles/{roleId}/data-scope | system:role:edit | RoleDataScopeUpdateDTO | Result<Void> | 更新角色数据范围 |

---

## DTO / VO 契约

### RoleDataScopeUpdateDTO（更新请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| deptIds | List<Long> | @NotNull | 部门 ID 列表 |

**禁止字段**：`id`、`roleId`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### RoleDataScopeVO（响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| roleId | Long | 角色 ID |
| deptIds | List<Long> | 部门 ID 列表 |
| deptNames | List<String> | 部门名称列表 |

**禁止字段**：`tenantId`、`deleted`、`createdBy`、`updatedBy`、`version`

---

## 业务规则

> 格式：BL-44-{序号}：[条件] → [动作] → [结果/异常]

- **BL-44-01**：角色 data_scope=CUSTOM → 查询 sys_role_data_scope → 获取自定义部门列表
- **BL-44-02**：角色 data_scope!=CUSTOM → 忽略 sys_role_data_scope → 使用固定规则
- **BL-44-03**：更新角色数据范围 → 删除旧记录 + 插入新记录 → 失效 dataScopeCache
- **BL-44-04**：用户有多个角色 → 合并所有角色的数据范围 → OR 逻辑
- **BL-44-05**：用户有 ALL 数据范围的角色 → 直接返回所有数据 → 不拼接 WHERE 条件
- **BL-44-06**：DataScopeInterceptor 拦截查询 → 根据角色数据范围拼接 SQL → 动态添加 WHERE 条件
- **BL-44-07**：数据范围缓存 → Caffeine L1 + Redis L2 → TTL 300s
- **BL-44-08**：角色删除 → 级联删除 sys_role_data_scope → 失效缓存

---

## 数据范围类型

| 类型 | 说明 | SQL 条件 |
|------|------|----------|
| **ALL** | 全部数据 | 无条件 |
| **DEPT** | 本部门数据 | `dept_id = #{userDeptId}` |
| **DEPT_AND_CHILD** | 本部门及子部门数据 | `dept_id IN (SELECT id FROM sys_dept WHERE find_in_set(#{userDeptId}, ancestors))` |
| **SELF** | 仅本人数据 | `created_by = #{userId}` |
| **CUSTOM** | 自定义部门数据 | `dept_id IN (#{customDeptIds})` |

---

## 核心组件契约

### DataScopeContext (ThreadLocal)

```java
/**
 * 数据范围上下文 (避免 data 模块依赖 web 模块)
 * 由 Filter 在请求开始时设置,在 Interceptor 中读取
 */
public class DataScopeContext {
    private static final ThreadLocal<DataScopeInfo> CONTEXT = new ThreadLocal<>();

    public static void set(Long userId, Long deptId, List<Long> roleIds) {
        CONTEXT.set(new DataScopeInfo(userId, deptId, roleIds));
    }

    public static DataScopeInfo get() {
        return CONTEXT.get();
    }

    public static void clear() {
        CONTEXT.remove();
    }

    public static class DataScopeInfo {
        private final Long userId;
        private final Long deptId;
        private final List<Long> roleIds;

        public DataScopeInfo(Long userId, Long deptId, List<Long> roleIds) {
            this.userId = userId;
            this.deptId = deptId;
            this.roleIds = roleIds;
        }

        // getters...
    }
}
```

### DataScopeInterceptor

```java
@Component
@Intercepts({
    @Signature(type = Executor.class, method = "query", args = {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class})
})
public class DataScopeInterceptor implements Interceptor {

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        // 1. 从 ThreadLocal 获取用户信息 (避免依赖 SecurityUtils)
        DataScopeContext.DataScopeInfo dataScopeInfo = DataScopeContext.get();
        if (dataScopeInfo == null) {
            return invocation.proceed();
        }

        // 2. 获取用户所有角色的数据范围
        List<DataScope> dataScopes = getDataScopes(dataScopeInfo.getRoleIds());

        // 3. 如果有 ALL 数据范围,直接返回
        if (dataScopes.contains(DataScope.ALL)) {
            return invocation.proceed();
        }

        // 4. 拼接 SQL 条件
        MappedStatement mappedStatement = (MappedStatement) invocation.getArgs()[0];
        BoundSql boundSql = mappedStatement.getBoundSql(invocation.getArgs()[1]);
        String originalSql = boundSql.getSql();

        // 5. 动态添加 WHERE 条件
        List<Object> dataScopeParams = new ArrayList<>();
        String dataScopeSql = buildDataScopeSql(dataScopes, dataScopeInfo, dataScopeParams);
        String newSql = originalSql + " AND (" + dataScopeSql + ")";

        // 6. 绑定参数到 BoundSql (防止 SQL 注入)
        MetaObject metaObject = SystemMetaObject.forObject(boundSql);
        for (int i = 0; i < dataScopeParams.size(); i++) {
            metaObject.setValue("additionalParameters.dataScope_param_" + i, dataScopeParams.get(i));
        }

        // 7. 替换 SQL
        Field field = BoundSql.class.getDeclaredField("sql");
        field.setAccessible(true);
        field.set(boundSql, newSql);

        return invocation.proceed();
    }

    private String buildDataScopeSql(List<DataScope> dataScopes, DataScopeContext.DataScopeInfo dataScopeInfo, List<Object> params) {
        List<String> conditions = new ArrayList<>();

        for (DataScope dataScope : dataScopes) {
            switch (dataScope) {
                case DEPT:
                    conditions.add("dept_id = ?");
                    params.add(dataScopeInfo.getDeptId());
                    break;
                case DEPT_AND_CHILD:
                    // PostgreSQL 兼容: 使用 ANY + string_to_array 替代 find_in_set
                    conditions.add("? = ANY(string_to_array(ancestors, ',')::bigint[])");
                    params.add(dataScopeInfo.getDeptId());
                    break;
                case SELF:
                    conditions.add("created_by = ?");
                    params.add(dataScopeInfo.getUserId());
                    break;
                case CUSTOM:
                    List<Long> customDeptIds = getCustomDeptIds(dataScopeInfo.getRoleIds());
                    if (!customDeptIds.isEmpty()) {
                        String placeholders = String.join(",", Collections.nCopies(customDeptIds.size(), "?"));
                        conditions.add("dept_id IN (" + placeholders + ")");
                        params.addAll(customDeptIds);
                    }
                    break;
            }
        }

        return String.join(" OR ", conditions);
    }

    @Cacheable(
        cacheName = "dataScopeCache",
        key = "#roleIds",
        level = CacheLevel.CAFFEINE_REDIS,
        ttl = 300
    )
    private List<Long> getCustomDeptIds(List<Long> roleIds) {
        return roleDataScopeRepository.findDeptIdsByRoleIds(roleIds);
    }
}
```

### DataScopeContextFilter

```java
@Component
@Order(2)  // 在 TenantContextFilter 之后执行
public class DataScopeContextFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            // 从 SecurityContext 获取用户信息并设置到 ThreadLocal
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.getPrincipal() instanceof LoginUser) {
                LoginUser loginUser = (LoginUser) authentication.getPrincipal();
                DataScopeContext.set(
                    loginUser.getUserId(),
                    loginUser.getDeptId(),
                    loginUser.getRoleIds()
                );
            }

            filterChain.doFilter(request, response);
        } finally {
            DataScopeContext.clear();
        }
    }
}
```

---

## 缓存策略

```java
@Cacheable(
    cacheName = "dataScopeCache",
    key = "#roleIds",
    level = CacheLevel.CAFFEINE_REDIS,
    ttl = 300
)
public List<Long> getCustomDeptIdsByRoleIds(List<Long> roleIds) {
    // ...
}
```

**缓存失效**:
- 角色数据范围更新时,失效 `dataScopeCache:{roleIds}`
- 通过 Outbox 事件 + Pub/Sub 广播失效

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-44-role-data-scope.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-44-01 | 无 Token → 401 | P0 |
| TC-44-02 | 无权限 → 403 | P0 |
| TC-44-03 | 查询角色数据范围 | P0 |
| TC-44-04 | 更新角色数据范围 | P0 |
| TC-44-05 | CUSTOM 数据范围生效 | P0 |
| TC-44-06 | 多角色数据范围合并 | P0 |
| TC-44-07 | ALL 数据范围跳过拦截 | P0 |
| TC-44-08 | 数据范围缓存生效 | P0 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`
- **AC-03**：DTO 不含禁止字段
- **AC-04**：CUSTOM 数据范围正确拼接 SQL
- **AC-05**：多角色数据范围正确合并（OR 逻辑）
- **AC-06**：ALL 数据范围跳过拦截
- **AC-07**：数据范围缓存生效（Caffeine L1 + Redis L2）
- **AC-08**：角色数据范围更新后缓存失效
- **AC-09**：编译通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:role:edit')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · 在 DTO 中声明禁止字段
- 数据范围合并：多角色使用 OR 逻辑
- ALL 数据范围：跳过所有拦截,不拼接 WHERE 条件
- 缓存策略：CAFFEINE_REDIS,TTL 300s
- SQL 注入防护：使用 PreparedStatement,禁止字符串拼接
