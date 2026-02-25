---
phase: 30
title: "Data Change Audit and Log Cleanup Job"
targets:
  backend: true
  frontend: false
depends_on: [29]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V030__create_sys_data_change_log.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDataChangeLog.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDataChangeLogMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysDataChangeLogMapper.xml"
  - "ljwx-platform-data/src/main/java/com/ljwx/platform/data/annotation/AuditChange.java"
  - "ljwx-platform-data/src/main/java/com/ljwx/platform/data/interceptor/DataChangeInterceptor.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/DataChangeLogController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/DataChangeLogAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/DataChangeLogVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/quartz/LogCleanupJob.java"
---
# Phase 30: Data Change Audit & Log Cleanup

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §DAG 依赖、§审计字段
- `spec/04-database.md` — 审计字段规范
- `spec/08-output-rules.md`

## 任务

### 1. 数据变更审计表（V030）

**表 sys_data_change_log**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| table_name | VARCHAR(64) NOT NULL | 表名 |
| record_id | BIGINT NOT NULL | 记录 ID |
| field_name | VARCHAR(64) NOT NULL | 字段名 |
| old_value | TEXT NOT NULL DEFAULT '' | 变更前值 |
| new_value | TEXT NOT NULL DEFAULT '' | 变更后值 |
| operate_type | VARCHAR(16) NOT NULL | UPDATE / DELETE |
| + 7 列审计字段 | | |

### 2. @AuditChange 注解（data 模块）

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface AuditChange {
    String tableName();   // 表名
    String idField() default "id"; // 主键字段名
}
```

### 3. DataChangeInterceptor（data 模块）

MyBatis `Interceptor`，拦截 `UPDATE` 和 `DELETE` 语句：
- 执行前：根据 SQL 解析出 WHERE 条件中的 id，查询旧值（`SELECT * FROM {table} WHERE id = ?`）
- 执行后：再次查询新值，对比差异
- 将差异写入 `sys_data_change_log`（异步写入，使用 `@Async`）
- 仅对标注 `@AuditChange` 的 Mapper 方法生效（通过 `MappedStatement` 的 id 匹配）

注意：DataChangeInterceptor 在 data 模块，**禁止 import security 包**（DAG 约束）。tenantId 从 `CurrentTenantHolder`（core 模块）获取，userId 从 `CurrentUserHolder`（core 模块）获取。

### 4. DataChangeLogController

```
GET /api/v1/data-change-logs  权限: system:audit:list
```

支持按 tableName、recordId、时间范围查询，分页返回。

### 5. 日志清理定时任务

**LogCleanupJob**（在 app 模块 quartz 包）：
- Cron: `0 0 2 * * ?`（每天凌晨 2 点）
- 读取 `sys_config` 中 `system.log.retention.days`（默认 90）
- 清理 `sys_operation_log`、`sys_login_log`、`sys_frontend_error` 中超过保留期的记录
- 每次最多删除 1000 条（分批删除，避免长事务）

## 关键约束

- DataChangeInterceptor 在 data 模块，禁止 import security 包（DAG 合规）
- 异步写入使用 `@Async`（复用 `LogAsyncConfig` 已有的线程池）
- V030 含 7 列审计字段，无 IF NOT EXISTS
- LogCleanupJob 使用 `@DisallowConcurrentExecution`（防止并发执行）

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V030__create_sys_data_change_log.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDataChangeLog.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDataChangeLogMapper.java
ljwx-platform-app/src/main/resources/mapper/SysDataChangeLogMapper.xml
ljwx-platform-data/src/main/java/com/ljwx/platform/data/annotation/AuditChange.java
ljwx-platform-data/src/main/java/com/ljwx/platform/data/interceptor/DataChangeInterceptor.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/DataChangeLogController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/DataChangeLogAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/DataChangeLogVO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/quartz/LogCleanupJob.java
```

## 验收条件

1. V030 含 7 列审计字段，无 IF NOT EXISTS
2. DataChangeInterceptor 无 security 包 import（DAG 合规）
3. DataChangeLogController 有 @PreAuthorize
4. LogCleanupJob 有 @DisallowConcurrentExecution
5. 编译通过

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-30-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-30-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-30-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-30-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-30-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-30-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-30-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-30-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-30-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-30-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
