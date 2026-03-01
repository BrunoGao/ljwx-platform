---
phase: 42
title: "Super Admin Mechanism"
targets:
  backend: true
  frontend: false
depends_on: [41]
bundle_with: []
scope:
  - "ljwx-platform-data/src/main/java/com/ljwx/platform/data/interceptor/TenantLineHandler.java"
  - "ljwx-platform-security/src/main/java/com/ljwx/platform/security/util/SecurityUtils.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/TenantContextFilter.java"
---
# Phase 42: Super Admin Mechanism

## Overview

| 属性 | 值 |
|------|-----|
| Phase | 42 |
| 模块 | ljwx-platform-data / ljwx-platform-security / ljwx-platform-web |
| Feature | tenant_id=0 跳过租户过滤 + 超级管理员权限 |
| 前置依赖 | Phase 41 |
| 测试契约 | [spec/tests/phase-42-super-admin.tests.yml](../tests/phase-42-super-admin.tests.yml) |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §审计字段、§DAG 依赖
- `docs/reference/list.md` — L1-D01 租户管理

## DB 契约

无新增表或字段。

## API 契约

无新增接口。超级管理员使用现有接口,但跳过租户过滤。

## 组件契约

| 组件 | 位置 | 核心行为 |
|------|------|----------|
| TenantLineHandler | data 模块 | MyBatis-Plus 租户拦截器,tenant_id=0 时跳过 WHERE tenant_id = ? 条件 |
| SecurityUtils | security 模块 | isSuperAdmin() 判断当前用户是否为超级管理员 (tenant_id=0) |
| TenantContextFilter | web 模块 | 超级管理员可通过 X-Tenant-Id header 切换租户上下文 |

## 业务规则

| 规则 | 条件 → 结果 |
|------|-------------|
| BL-42-01 | 用户 tenant_id=0 → 超级管理员,跳过所有租户过滤 |
| BL-42-02 | 超级管理员查询 sys_user → 返回所有租户的用户 |
| BL-42-03 | 超级管理员请求时携带 X-Tenant-Id header → TenantContext 设置为指定租户,后续查询仅返回该租户数据 |
| BL-42-04 | 超级管理员未携带 X-Tenant-Id header → TenantContext.tenantId=0,查询返回所有租户数据 |
| BL-42-05 | 普通用户携带 X-Tenant-Id header → 忽略,TenantContext 仍为用户所属租户 |
| BL-42-06 | 超级管理员创建数据时未指定 tenant_id → 使用 TenantContext.tenantId (可能为 0 或指定租户) |

## P0 测试摘要

| TC ID | 场景 | 预期 |
|-------|------|------|
| TC-42-01 | 超级管理员 (tenant_id=0) GET /api/v1/users | 200, 返回所有租户的用户 |
| TC-42-02 | 超级管理员携带 X-Tenant-Id: 1 GET /api/v1/users | 200, 仅返回 tenant_id=1 的用户 |
| TC-42-03 | 普通用户 (tenant_id=1) 携带 X-Tenant-Id: 2 GET /api/v1/users | 200, 仅返回 tenant_id=1 的用户 (忽略 header) |
| TC-42-04 | 超级管理员 POST /api/v1/users (未指定 tenant_id) | 200, 用户 tenant_id=0 |
| TC-42-05 | 超级管理员携带 X-Tenant-Id: 1 POST /api/v1/users (未指定 tenant_id) | 200, 用户 tenant_id=1 |
| TC-42-06 | SecurityUtils.isSuperAdmin() 对 tenant_id=0 用户 | 返回 true |
| TC-42-07 | SecurityUtils.isSuperAdmin() 对 tenant_id=1 用户 | 返回 false |

完整测试用例见 [spec/tests/phase-42-super-admin.tests.yml](../tests/phase-42-super-admin.tests.yml)。

## 关键约束

- TenantLineHandler 在 data 模块,可以访问 TenantContext
- SecurityUtils 在 security 模块,禁止 import data 模块
- TenantContextFilter 在 web 模块,禁止 import data 模块
- 超级管理员的 tenant_id 必须为 0,不能为 NULL
- 超级管理员切换租户上下文时,必须验证目标租户存在
- 超级管理员创建数据时,tenant_id 默认使用 TenantContext.tenantId

## 验收条件

1. 超级管理员 (tenant_id=0) 可以查询所有租户的数据
2. 超级管理员携带 X-Tenant-Id header 可以切换租户上下文
3. 普通用户携带 X-Tenant-Id header 无效,仍然只能访问自己租户的数据
4. SecurityUtils.isSuperAdmin() 正确判断超级管理员
5. 超级管理员创建数据时,tenant_id 正确设置
6. 编译通过,无 DAG 违规
7. 所有 P0 测试用例通过

## 实施建议

### 1. TenantLineHandler

```java
@Component
public class TenantLineHandler implements TenantLineHandler {
    @Override
    public Expression getTenantId() {
        Long tenantId = TenantContext.getTenantId();
        // 超级管理员 (tenant_id=0) 跳过租户过滤
        if (tenantId == null || tenantId == 0) {
            return null;
        }
        return new LongValue(tenantId);
    }

    @Override
    public boolean ignoreTable(String tableName) {
        // 平台级表 (无 tenant_id 列) 跳过
        return PLATFORM_TABLES.contains(tableName);
    }
}
```

### 2. SecurityUtils

```java
public class SecurityUtils {
    /**
     * 判断当前用户是否为超级管理员
     */
    public static boolean isSuperAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return false;
        }

        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        if (userDetails instanceof LoginUser) {
            LoginUser loginUser = (LoginUser) userDetails;
            return loginUser.getTenantId() != null && loginUser.getTenantId() == 0;
        }
        return false;
    }
}
```

### 3. TenantContextFilter

```java
@Component
@Order(1)
public class TenantContextFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request, ...) {
        try {
            Long tenantId = resolveTenantId(request);
            TenantContext.setTenantId(tenantId);
            chain.doFilter(request, response);
        } finally {
            TenantContext.clear();
        }
    }

    private Long resolveTenantId(HttpServletRequest request) {
        // 1. 从认证信息获取用户租户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof LoginUser) {
            LoginUser loginUser = (LoginUser) authentication.getPrincipal();
            Long userTenantId = loginUser.getTenantId();

            // 2. 超级管理员可以通过 header 切换租户
            if (userTenantId != null && userTenantId == 0) {
                String headerTenantId = request.getHeader("X-Tenant-Id");
                if (StringUtils.hasText(headerTenantId)) {
                    return Long.parseLong(headerTenantId);
                }
            }

            return userTenantId;
        }

        // 3. 未认证请求,返回 null
        return null;
    }
}
```

### 4. 超级管理员初始化

```sql
-- 在 V001 或 V002 中初始化超级管理员
INSERT INTO sys_user (
    id, tenant_id, dept_id, username, password, nickname,
    email, phone, status,
    created_by, created_time, updated_by, updated_time, deleted, version
) VALUES (
    1, 0, 0, 'superadmin', '$2a$10$...', '超级管理员',
    'superadmin@ljwx.com', '13800000000', TRUE,
    0, NOW(), 0, NOW(), FALSE, 1
);

-- 创建超级管理员角色
INSERT INTO sys_role (
    id, tenant_id, role_name, role_code, data_scope, sort_order, status,
    created_by, created_time, updated_by, updated_time, deleted, version
) VALUES (
    1, 0, '超级管理员', 'SUPER_ADMIN', 'ALL', 0, TRUE,
    0, NOW(), 0, NOW(), FALSE, 1
);

-- 分配角色
INSERT INTO sys_user_role (user_id, role_id, tenant_id) VALUES (1, 1, 0);
```

## 安全注意事项

1. **超级管理员密码**: 必须使用强密码,定期更换
2. **审计日志**: 超级管理员的所有操作必须记录到 sys_operation_log
3. **切换租户**: 超级管理员切换租户时,必须记录到审计日志
4. **权限控制**: 超级管理员仍然受权限控制,不是"无限权限"
5. **数据隔离**: 超级管理员创建数据时,必须明确指定 tenant_id

## 相关文档

- [Phase 41: 租户生命周期管理](./phase-41.md)
- [Phase 43: 租户域名识别](./phase-43.md)
