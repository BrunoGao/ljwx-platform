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
