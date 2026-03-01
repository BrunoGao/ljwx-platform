---
phase: 41
title: "Tenant Lifecycle Management"
targets:
  backend: true
  frontend: true
depends_on: [40]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/TenantInitializer.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/TenantLifecycleService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/TenantLifecycleController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/filter/TenantLifecycleFilter.java"
  - "ljwx-platform-app/src/main/resources/db/migration/V042__add_tenant_lifecycle_fields.sql"
  - "ljwx-platform-admin/src/views/system/tenant/lifecycle.vue"
---
# Phase 41: Tenant Lifecycle Management

## Overview

| 属性 | 值 |
|------|-----|
| Phase | 41 |
| 模块 | ljwx-platform-app / ljwx-platform-admin |
| Feature | 租户初始化器 + 冻结/注销机制 + 生命周期管理 |
| 前置依赖 | Phase 40 |
| 测试契约 | [spec/tests/phase-41-tenant-lifecycle.tests.yml](../tests/phase-41-tenant-lifecycle.tests.yml) |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §审计字段、§DAG 依赖
- `spec/04-database.md` — 审计字段规范
- `docs/adr/ADR-0004-outbox-pattern.md` — Outbox 事件
- `docs/reference/list.md` — L1-D01 租户管理

## DB 契约

### sys_tenant 新增字段（V037）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| lifecycle_status | VARCHAR(20) | NOT NULL DEFAULT 'ACTIVE' | 生命周期状态: ACTIVE/FROZEN/CANCELLED |
| frozen_reason | VARCHAR(500) | NULL | 冻结���因 |
| frozen_time | TIMESTAMP | NULL | 冻结时间 |
| cancelled_reason | VARCHAR(500) | NULL | 注销原因 |
| cancelled_time | TIMESTAMP | NULL | 注销时间 |

### Flyway 文件

| 文件 | 说明 |
|------|------|
| V042__add_tenant_lifecycle_fields.sql | 为 sys_tenant 添加生命周期字段,禁止 IF NOT EXISTS |

## API 契约

| 方法 | 路径 | 权限 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | /api/v1/tenants/{id}/freeze | system:tenant:freeze | TenantFreezeDTO | Result\<Void\> |
| POST | /api/v1/tenants/{id}/unfreeze | system:tenant:unfreeze | — | Result\<Void\> |
| POST | /api/v1/tenants/{id}/cancel | system:tenant:cancel | TenantCancelDTO | Result\<Void\> |
| POST | /api/v1/tenants/{id}/initialize | system:tenant:init | — | Result\<Void\> |

### TenantFreezeDTO 字段

| 字段 | 类型 | 约束 |
|------|------|------|
| reason | String | @NotBlank, @Size(max=500) |

### TenantCancelDTO 字段

| 字段 | 类型 | 约束 |
|------|------|------|
| reason | String | @NotBlank, @Size(max=500) |

## 组件契约

| 组件 | 位置 | 核心行为 |
|------|------|----------|
| TenantInitializer | app 模块 | 租户创建后初始化: 创建默认管理员、默认角色、默认菜单、默认部门 |
| TenantLifecycleService | app 模块 | freeze(tenantId, reason) / unfreeze(tenantId) / cancel(tenantId, reason) |
| TenantLifecycleFilter | app 模块 | 拦截所有请求,检查 TenantContext.tenantId 的 lifecycle_status,FROZEN/CANCELLED 返回 403 |
| TenantLifecycleController | app 模块 | 租户生命周期管理接口 |

## 业务规则

| 规则 | 条件 → 结果 |
|------|-------------|
| BL-41-01 | 租户创建成功 → TenantInitializer 自动初始化: 创建默认管理员(username=admin)、默认角色(TENANT_ADMIN)、默认部门(根部门) |
| BL-41-02 | 冻结租户 → lifecycle_status=FROZEN, frozen_reason/frozen_time 记录,写 Outbox 事件 TenantFrozen |
| BL-41-03 | 解冻租户 → lifecycle_status=ACTIVE, frozen_reason/frozen_time 清空,写 Outbox 事件 TenantUnfrozen |
| BL-41-04 | 注销租户 → lifecycle_status=CANCELLED, cancelled_reason/cancelled_time 记录,写 Outbox 事件 TenantCancelled |
| BL-41-05 | 冻结/注销的租户 → TenantLifecycleFilter 拦截所有请求,返回 403 Forbidden |
| BL-41-06 | 租户初始化失败 → 回滚租户创建,返回错误信息 |

## P0 测试摘要

| TC ID | 场景 | 预期 |
|-------|------|------|
| TC-41-01 | POST /api/v1/tenants 创建租户 → 自动初始化 | 200, sys_user/sys_role/sys_dept 自动创建 |
| TC-41-02 | POST /api/v1/tenants/{id}/freeze 冻结租户 | 200, lifecycle_status=FROZEN, sys_outbox_event 写入 TenantFrozen |
| TC-41-03 | 冻结租户后,该租户用户请求任意接口 | 403, message="租户已冻结" |
| TC-41-04 | POST /api/v1/tenants/{id}/unfreeze 解冻租户 | 200, lifecycle_status=ACTIVE, sys_outbox_event 写入 TenantUnfrozen |
| TC-41-05 | POST /api/v1/tenants/{id}/cancel 注销租户 | 200, lifecycle_status=CANCELLED, sys_outbox_event 写入 TenantCancelled |
| TC-41-06 | 注销租户后,该租户用户请求任意接口 | 403, message="租户已注销" |
| TC-41-07 | V042 含 5 个新字段,无 IF NOT EXISTS | 通过 |

完整测试用例见 [spec/tests/phase-41-tenant-lifecycle.tests.yml](../tests/phase-41-tenant-lifecycle.tests.yml)。

## 关键约束

- TenantInitializer 在 app 模块,可以 import data 模块
- TenantLifecycleFilter 在 app 模块,可以直接查询 TenantRepository
- V042 含 5 个新字段,无 IF NOT EXISTS
- 冻结/解冻/注销操作必须写 Outbox 事件,保证最终一致性
- 租户初始化必须在事务内完成,失败则回滚
- 默认管理员密码必须符合强密码规则 (Phase 28)

## 验收条件

1. 租户创建后自动初始化默认管理员/角色/部门
2. 冻结租户后,该租户用户无法访问任何接口 (403)
3. 解冻租户后,该租户用户恢复正常访问
4. 注销租户后,该租户用户无法访问任何接口 (403)
5. V042 含 5 个新字段,无 IF NOT EXISTS
6. 冻结/解冻/注销操作写入 sys_outbox_event
7. 编译通过,无 DAG 违规
8. 所有 P0 测试用例通过

## 实施建议

### 1. 租户初始化器

```java
@Service
@RequiredArgsConstructor
public class TenantInitializer {
    private final UserService userService;
    private final RoleService roleService;
    private final DeptService deptService;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public void initialize(Long tenantId) {
        // 1. 创建根部门
        Dept rootDept = Dept.builder()
            .tenantId(tenantId)
            .parentId(0L)
            .deptName("根部门")
            .sortOrder(0)
            .status(true)
            .build();
        deptService.create(rootDept);

        // 2. 创建默认角色
        Role adminRole = Role.builder()
            .tenantId(tenantId)
            .roleName("租户管理员")
            .roleCode("TENANT_ADMIN")
            .dataScope(DataScope.ALL)
            .sortOrder(0)
            .status(true)
            .build();
        roleService.create(adminRole);

        // 3. 创建默认管理员
        User admin = User.builder()
            .tenantId(tenantId)
            .deptId(rootDept.getId())
            .username("admin")
            .password(passwordEncoder.encode("Admin@12345"))
            .nickname("管理员")
            .status(true)
            .build();
        userService.create(admin);

        // 4. 分配角色
        userService.assignRoles(admin.getId(), List.of(adminRole.getId()));
    }
}
```

### 2. 生命周期过滤器

```java
@Component
@Order(2)
public class TenantLifecycleFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request, ...) {
        Long tenantId = TenantContext.getTenantId();
        if (tenantId == null || tenantId == 0) {
            chain.doFilter(request, response);
            return;
        }

        Tenant tenant = tenantService.getById(tenantId);
        if (tenant.getLifecycleStatus() == LifecycleStatus.FROZEN) {
            response.setStatus(403);
            response.getWriter().write("{\"code\":403,\"message\":\"租户已冻结\"}");
            return;
        }
        if (tenant.getLifecycleStatus() == LifecycleStatus.CANCELLED) {
            response.setStatus(403);
            response.getWriter().write("{\"code\":403,\"message\":\"租户已注销\"}");
            return;
        }

        chain.doFilter(request, response);
    }
}
```

### 3. Outbox 事件

```java
@Transactional
public void freeze(Long tenantId, String reason) {
    // 1. 更新租户状态
    tenantRepository.updateLifecycleStatus(tenantId, LifecycleStatus.FROZEN, reason);

    // 2. 写 Outbox 事件
    OutboxEvent event = OutboxEvent.builder()
        .eventType("TENANT_FROZEN")
        .aggregateId(tenantId)
        .payload(toJson(Map.of("tenantId", tenantId, "reason", reason)))
        .status(OutboxStatus.PENDING)
        .build();
    outboxRepository.save(event);
}
```

## 相关 ADR

- [ADR-0004: Outbox Pattern](../../docs/adr/ADR-0004-outbox-pattern.md)

## 相关文档

- [Phase 40: 岗位管理](./phase-40.md)
- [Phase 42: 超级管理员机制](./phase-42.md)
