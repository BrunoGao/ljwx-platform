---
phase: 5
title: "App Skeleton"
targets:
  backend: true
  frontend: false
depends_on: [4]
bundle_with: [4]
scope:
  - "ljwx-platform-app/pom.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/LjwxPlatformApplication.java"
  - "ljwx-platform-app/src/main/resources/application.yml"
  - "ljwx-platform-app/src/main/resources/db/migration/V001__init_schema.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V002__create_user.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V003__create_role.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V004__create_permission.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V005__seed_default_tenant.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V006__seed_admin_user.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V007__seed_permissions.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V008__seed_admin_role.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V009__assign_admin_role.sql"
---
# Phase 5: App Skeleton

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-architecture.md` — §POM 依赖声明（app 部分）
- `spec/04-database.md` — V001 ~ V009
- `spec/05-backend-config.md` — §application.yml 骨架
- `spec/01-constraints.md` — §审计字段、§RBAC 权限
- `spec/08-output-rules.md`

## 任务

实现 ljwx-platform-app 骨架：Spring Boot Main、application.yml、Flyway V001-V009（基础表 + 种子数据）。

## Phase-Local Manifest

```
ljwx-platform-app/pom.xml
ljwx-platform-app/src/main/java/com/ljwx/platform/app/LjwxPlatformApplication.java
ljwx-platform-app/src/main/resources/application.yml
ljwx-platform-app/src/main/resources/db/migration/V001__init_schema.sql
ljwx-platform-app/src/main/resources/db/migration/V002__create_user.sql
ljwx-platform-app/src/main/resources/db/migration/V003__create_role.sql
ljwx-platform-app/src/main/resources/db/migration/V004__create_permission.sql
ljwx-platform-app/src/main/resources/db/migration/V005__seed_default_tenant.sql
ljwx-platform-app/src/main/resources/db/migration/V006__seed_admin_user.sql
ljwx-platform-app/src/main/resources/db/migration/V007__seed_permissions.sql
ljwx-platform-app/src/main/resources/db/migration/V008__seed_admin_role.sql
ljwx-platform-app/src/main/resources/db/migration/V009__assign_admin_role.sql
```

## 验收条件

1. `pom.xml` 依赖含 `ljwx-platform-web` + `ljwx-platform-data`
2. application.yml 与 spec/05-backend-config.md 一致
3. V001-V004 的 CREATE TABLE 均含 7 列审计字段
4. V006 中 admin 密码使用 BCrypt cost=10 的 hash
5. V007 包含 spec/01-constraints.md §RBAC 中的所有权限字符串
6. 无 `IF NOT EXISTS`
7. `./mvnw compile -pl ljwx-platform-app` 通过

## 可 Bundle

可与 Phase 4 一起执行。
