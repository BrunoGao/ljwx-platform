---
phase: 2
title: "Data Module"
targets:
  backend: true
  frontend: false
depends_on: [1]
bundle_with: [3]
scope:
  - "ljwx-platform-data/**"
---
# Phase 2: Data Module

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §审计字段、§多租户行级隔离
- `spec/02-architecture.md` — §模块依赖图、§Core 模块关键接口、§POM 依赖声明（data 部分）
- `spec/08-output-rules.md`

## 任务

实现 ljwx-platform-data 模块：AuditFieldInterceptor、TenantLineInterceptor、MyBatis 配置。

## 关键约束

- data 模块**仅依赖 core**，import 路径只能出现 `com.ljwx.platform.core.*`
- AuditFieldInterceptor 通过 `CurrentUserHolder`（core 接口）获取用户 ID
- TenantLineInterceptor 通过 `CurrentTenantHolder`（core 接口）获取租户 ID
- 实现类由 security 模块在运行时通过 Spring DI 提供

## Phase-Local Manifest

```
ljwx-platform-data/pom.xml
ljwx-platform-data/src/main/java/com/ljwx/platform/data/interceptor/AuditFieldInterceptor.java
ljwx-platform-data/src/main/java/com/ljwx/platform/data/interceptor/TenantLineInterceptor.java
ljwx-platform-data/src/main/java/com/ljwx/platform/data/config/MyBatisConfig.java
```

## 验收条件

1. `pom.xml` 依赖仅含 `ljwx-platform-core`，无 `ljwx-platform-security`
2. 全部 import 语句无 `com.ljwx.platform.security`
3. AuditFieldInterceptor 处理 INSERT 和 UPDATE
4. TenantLineInterceptor 自动追加 `WHERE tenant_id = ?`
5. `./mvnw compile -pl ljwx-platform-data` 通过

## 可 Bundle

可与 Phase 3 一起执行，但分开输出。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-02-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-02-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-02-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-02-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-02-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-02-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-02-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-02-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-02-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-02-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
