# ADR-0009: 工作流可见性模型 (Workflow Visibility Model)

## 状态
**已接受** (Accepted) - 2025-03-01

## 背景
LJWX Platform 需要实现简化版流程引擎,支持审批流、任务流等场景。在多租户 SaaS 环境下,需要明确定义工作流实例和任务的可见性规则,确保:
1. 数据隔离 - 租户间数据完全隔离
2. 权限控制 - 用户只能看到有权限的流程和任务
3. 部门范围 - 支持按部门范围控制可见性
4. 角色范围 - 支持按角色范围控制可见性

## 决策
采用 **6 级可见性模型**,从严格到宽松依次为:

### Level 0: 租户隔离 (Tenant Isolation)
- **规则**: 所有查询自动添加 `tenant_id = #{currentTenantId}` 条件
- **实现**: TenantInterceptor (MyBatis 拦截器)
- **适用**: 所有表（除 sys_tenant 等系统表）

### Level 1: 仅创建人可见 (Creator Only)
- **规则**: `created_by = #{currentUserId}`
- **适用**: 草稿流程、个人任务
- **示例**: 用户只能看到自己创建的流程实例

### Level 2: 创建人 + 指定处理人可见 (Creator + Assignee)
- **规则**: `created_by = #{currentUserId} OR assignee_id = #{currentUserId}`
- **适用**: 待办任务、审批任务
- **示例**: 流程发起人和当前任务处理人可见

### Level 3: 本部门可见 (Department Scope)
- **规则**: `dept_id = #{currentUserDeptId}`
- **适用**: 部门内流程、部门任务
- **示例**: 部门经理可以看到本部门所有流程

### Level 4: 本部门及子部门可见 (Department and Children)
- **规则**: `dept_id IN (SELECT id FROM sys_dept WHERE ancestors @> ARRAY[#{currentUserDeptId}]::bigint[])`
- **适用**: 跨部门流程、上级审批
- **示例**: 总经理可以看到所有下属部门的流程

### Level 5: 全租户可见 (Tenant Wide)
- **规则**: 仅 `tenant_id = #{currentTenantId}` (无额外限制)
- **适用**: 公开流程、系统通知
- **示例**: 所有用户可以看到公司公告流程

### Level 6: 超级管理员可见 (Super Admin)
- **规则**: 无限制 (tenant_id = 0 的用户)
- **适用**: 平台管理员
- **示例**: 平台运维人员可以看到所有租户的流程

## 实现方案

### 1. 数据库设计
```sql
CREATE TABLE wf_instance (
    id BIGINT PRIMARY KEY,
    visibility_level INT NOT NULL DEFAULT 2,  -- 可见性级别
    dept_id BIGINT,  -- 部门 ID (Level 3/4 使用)
    assignee_id BIGINT,  -- 当前处理人 (Level 2 使用)
    -- ... 其他字段
    tenant_id BIGINT NOT NULL DEFAULT 0,
    created_by BIGINT NOT NULL DEFAULT 0,
    -- ... 审计字段
);
```

### 2. MyBatis 拦截器
```java
@Component
@Intercepts({
    @Signature(type = Executor.class, method = "query", ...)
})
public class WorkflowVisibilityInterceptor implements Interceptor {

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        LoginUser user = SecurityUtils.getLoginUser();
        if (user == null) {
            return invocation.proceed();
        }

        // 超级管理员跳过
        if (user.getTenantId() == 0) {
            return invocation.proceed();
        }

        // 根据 visibility_level 动态添加 WHERE 条件
        String sql = buildVisibilitySql(user);
        // ... 修改 SQL
    }

    private String buildVisibilitySql(LoginUser user) {
        // Level 0: 租户隔离 (始终添加)
        String sql = "tenant_id = " + user.getTenantId();

        // Level 1-5: 根据 visibility_level 添加条件
        // ...
    }
}
```

### 3. Service 层控制
```java
@Service
public class WorkflowInstanceService {

    public void createInstance(WorkflowInstanceCreateDTO dto) {
        WorkflowInstance instance = new WorkflowInstance();
        // ... 设置字段

        // 根据流程定义设置可见性级别
        WorkflowDefinition definition = definitionRepository.findById(dto.getDefinitionId());
        instance.setVisibilityLevel(definition.getDefaultVisibilityLevel());

        instanceRepository.insert(instance);
    }
}
```

## 优势
1. **灵活性**: 6 级可见性覆盖所有场景
2. **性能**: 通过索引优化查询性能
3. **安全性**: 多层防护,防止数据泄露
4. **可扩展**: 易于添加新的可见性级别

## 劣势
1. **复杂性**: 需要维护拦截器逻辑
2. **性能开销**: 每次查询都需要拼接 SQL
3. **调试难度**: SQL 动态生成,调试困难

## 替代方案

### 方案 A: 仅使用角色权限
- **优点**: 简单,易于理解
- **缺点**: 无法实现细粒度控制

### 方案 B: 使用 PostgreSQL RLS (Row Level Security)
- **优点**: 数据库层面强制执行
- **缺点**: 与 MyBatis 集成复杂,性能开销大

## 相关决策
- ADR-0001: 多级缓存策略
- ADR-0004: Outbox 事件模式
- ADR-0008: 数据变更审计

## 参考资料
- [PostgreSQL Row Level Security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [MyBatis Interceptor](https://mybatis.org/mybatis-3/configuration.html#plugins)
