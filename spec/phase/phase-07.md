---
phase: 7
title: "Quartz Integration"
targets:
  backend: true
  frontend: false
depends_on: [5]
bundle_with: [8]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V010__create_quartz_tables.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V011__create_sys_job.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/JobController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/JobAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysJob.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysJobMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysJobMapper.xml"
---
# Phase 7: Quartz Integration

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §Quartz 调度
- `spec/03-api.md` — §Jobs 路由
- `spec/04-database.md` — V010、V011
- `spec/08-output-rules.md`

## 任务

Quartz 集成：V010（Quartz 标准表）、V011（sys_job 业务表）、Job Controller / Service / Mapper、per-tenant 调度。

## 关键约束

- V010：Quartz 标准 PostgreSQL DDL，QRTZ_ 前缀，**无审计字段**，**无 IF NOT EXISTS**
- V011：sys_job 业务表，**含 7 列审计字段**
- JobKey 格式：`(name="{jobId}", group="TENANT_{tenantId}")`
- Controller 每个方法必须 `@PreAuthorize`

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V010__create_quartz_tables.sql
ljwx-platform-app/src/main/resources/db/migration/V011__create_sys_job.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/JobController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/JobAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysJob.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysJobMapper.java
ljwx-platform-app/src/main/resources/mapper/SysJobMapper.xml
```

## 验收条件

1. V010 含 QRTZ_ 表，无审计字段，无 IF NOT EXISTS
2. V011 含 7 列审计字段
3. JobController 所有方法有 @PreAuthorize，权限字符串匹配 spec/03-api.md
4. per-tenant 隔离：JobKey group 含 `TENANT_`
5. `./mvnw compile -pl ljwx-platform-app` 通过

## 可 Bundle

可与 Phase 8 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-07-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-07-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-07-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-07-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-07-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-07-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-07-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-07-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-07-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-07-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
