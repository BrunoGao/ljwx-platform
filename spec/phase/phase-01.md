---
phase: 1
title: "Core Module"
targets:
  backend: true
  frontend: false
depends_on: [0]
bundle_with: [0]
scope:
  - "ljwx-platform-core/**"
---
# Phase 1: Core Module

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §审计字段、§多租户行级隔离
- `spec/02-architecture.md` — §模块依赖图、§Core 模块关键接口
- `spec/03-api.md` — §统一响应、§错误码
- `spec/08-output-rules.md`

## 任务

实现 ljwx-platform-core 模块：Result、ErrorCode、BaseEntity、SnowflakeIdGenerator、CurrentUserHolder 接口、CurrentTenantHolder 接口。

## Phase-Local Manifest

```
ljwx-platform-core/pom.xml
ljwx-platform-core/src/main/java/com/ljwx/platform/core/result/Result.java
ljwx-platform-core/src/main/java/com/ljwx/platform/core/result/ErrorCode.java
ljwx-platform-core/src/main/java/com/ljwx/platform/core/result/PageResult.java
ljwx-platform-core/src/main/java/com/ljwx/platform/core/id/SnowflakeIdGenerator.java
ljwx-platform-core/src/main/java/com/ljwx/platform/core/entity/BaseEntity.java
ljwx-platform-core/src/main/java/com/ljwx/platform/core/context/CurrentUserHolder.java
ljwx-platform-core/src/main/java/com/ljwx/platform/core/context/CurrentTenantHolder.java
```

## 验收条件

1. `pom.xml` 无对其他 ljwx 模块的依赖
2. Result 类包含 code、message、data、traceId 字段
3. ErrorCode 枚举包含 spec/03-api.md 中定义的所有错误码
4. BaseEntity 包含 7 个审计字段（匹配 spec/01-constraints.md）
5. CurrentUserHolder 和 CurrentTenantHolder 是接口（非实现类）
6. `./mvnw compile -pl ljwx-platform-core` 通过

## 可 Bundle

可与 Phase 0 一起执行。
