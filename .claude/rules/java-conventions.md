---
paths:
  - "ljwx-platform-*/src/**/*.java"
  - "ljwx-platform-*/src/**/*.xml"
---

# Java 编码规范 — LJWX Platform

## 模块 DAG 依赖（硬规则）

```
core ← {security, data} ← web ← app
```

- `ljwx-platform-data/` **禁止** import `com.ljwx.platform.security.*`
- `ljwx-platform-security/` **禁止** import `com.ljwx.platform.data.*`
- `ljwx-platform-core/` **禁止** import 任何其他 `com.ljwx.platform.*` 模块
- `ljwx-platform-web/` 通过 security 间接依赖，**禁止**直接 import data

## 实体 / Mapper

- 所有业务实体必须继承 `BaseEntity`（含 7 列审计字段）
- 审计字段：`tenant_id`, `created_by`, `created_time`, `updated_by`, `updated_time`, `deleted`, `version`
- 使用 MyBatis-Plus `@TableName` 注解

## Service

- `tenant_id` 由 `TenantLineInterceptor` 自动注入，**禁止** `setTenantId()`
- 写操作加 `@Transactional`

## Controller

正确写法：
```java
@GetMapping
@PreAuthorize("hasAuthority('resource:action')")
public Result<PageResult<UserVO>> list(UserQueryDTO query) { ... }
```

- 每个 `@(Get|Post|Put|Delete|Patch)Mapping` 方法上方 **必须** 有 `@PreAuthorize`
- 格式：`hasAuthority('resource:action')`，**禁止** `hasRole(...)` 或 `ROLE_` 前缀
- 例外：路径含 `/auth/login` 或 `/auth/refresh` 的端点

## DTO / Request / Response

- **禁止** 出现 `tenantId` 或 `tenant_id` 字段
- 字段用 `@NotNull`、`@NotBlank`、`@Size` 等 Bean Validation 注解
- 命名：`XxxCreateDTO`、`XxxUpdateDTO`、`XxxQueryDTO`、`XxxVO`

## POM

- **禁止** `${latest.version}` 占位符
- 所有版本号必须硬编码数字
- 版本以 CLAUDE.md "版本锁定" 表为唯一来源

## 安全规范

- 密码字段日志输出 → `***`
- 手机号中间四位 → `*`
- 身份证中间段 → `*`
- BCrypt cost=10：`new BCryptPasswordEncoder(10)`
