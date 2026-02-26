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

## Overview

| 项目 | 内容 |
|------|------|
| Phase | 30 |
| 模块 | ljwx-platform-data / ljwx-platform-app |
| Feature | 字段级数据变更审计、变更日志查询、日志定时清理 |
| 前置依赖 | Phase 29 |
| 测试契约 | spec/tests/phase-30-audit.tests.yml |

## 读取清单
- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §DAG 依赖、§审计字段
- `spec/04-database.md` — 审计字段规范
- `spec/08-output-rules.md`

## DB 契约

### sys_data_change_log（V030）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键 |
| table_name | VARCHAR(64) | NOT NULL | 目标表名 |
| record_id | BIGINT | NOT NULL | 被变更记录 ID |
| field_name | VARCHAR(64) | NOT NULL | 变更字段名 |
| old_value | TEXT | NOT NULL DEFAULT '' | 变更前值 |
| new_value | TEXT | NOT NULL DEFAULT '' | 变更后值 |
| operate_type | VARCHAR(16) | NOT NULL | UPDATE / DELETE |
| tenant_id | BIGINT | NOT NULL DEFAULT 0 | 租户 ID（审计字段） |
| created_by | BIGINT | NOT NULL DEFAULT 0 | 创建人（审计字段） |
| created_time | TIMESTAMP | NOT NULL DEFAULT NOW() | 创建时间（审计字段） |
| updated_by | BIGINT | NOT NULL DEFAULT 0 | 更新人（审计字段） |
| updated_time | TIMESTAMP | NOT NULL DEFAULT NOW() | 更新时间（审计字段） |
| deleted | SMALLINT | NOT NULL DEFAULT 0 | 逻辑删除（审计字段） |
| version | INT | NOT NULL DEFAULT 0 | 乐观锁（审计字段） |

### Flyway 文件

| 文件 | 说明 |
|------|------|
| V030__create_sys_data_change_log.sql | 创建 sys_data_change_log 表，禁止 IF NOT EXISTS |

## API 契约

| 方法 | 路径 | 权限 | 请求参数 | 响应 |
|------|------|------|----------|------|
| GET | /api/v1/data-change-logs | system:audit:list | tableName / recordId / startTime / endTime / pageNum / pageSize | Result\<PageResult\<DataChangeLogVO\>\> |

### DataChangeLogVO 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| tableName | String | 目标表名 |
| recordId | Long | 被变更记录 ID |
| fieldName | String | 变更字段名 |
| oldValue | String | 变更前值 |
| newValue | String | 变更后值 |
| operateType | String | UPDATE / DELETE |
| createdBy | Long | 操作人 |
| createdTime | LocalDateTime | 操作时间 |

## 组件契约

| 组件 | 位置 | 核心行为 |
|------|------|----------|
| @AuditChange | data 模块 annotation | 注解属性：tableName（必填）、idField（默认 "id"）；标注在 Mapper 方法上 |
| DataChangeInterceptor | data 模块 interceptor | 拦截 UPDATE/DELETE，执行前查旧值，执行后查新值，对比差异后异步写入 sys_data_change_log |
| LogCleanupJob | app 模块 quartz | Cron: `0 0 2 * * ?`，读取 sys_config `system.log.retention.days`（默认 90），每次最多删 1000 条 |

## 业务规则

- **BL-30-01**：DataChangeInterceptor 仅对标注 `@AuditChange` 的 Mapper 方法生效，拦截 UPDATE/DELETE；执行前查旧值，执行后查新值，对比字段差异
- **BL-30-02**：差异记录通过 `@Async` 异步写入 sys_data_change_log，复用 Phase 9 已有的 LogAsyncConfig 线程池，不阻塞主业务
- **BL-30-03**：DataChangeInterceptor 在 data 模块，禁止 import 任何 `com.ljwx.platform.security.*` 包；tenantId 从 `CurrentTenantHolder`（core）获取，userId 从 `CurrentUserHolder`（core）获取
- **BL-30-04**：LogCleanupJob 每批次最多删除 1000 条记录，循环分批删除至目标数量，避免单次大事务锁表
- **BL-30-05**：保留天数从 sys_config 键 `system.log.retention.days` 读取，读取失败或缺失时默认使用 90 天

## P0 测试摘要

| ID | 优先级 | 场景 |
|----|--------|------|
| TC-30-01 | P0 | GET /api/v1/data-change-logs 无 Token → 401 |
| TC-30-02 | P0 | GET /api/v1/data-change-logs 缺 system:audit:list 权限 → 403 |
| TC-30-03 | P0 | GET /api/v1/data-change-logs 有权限 → 200 分页返回 |
| TC-30-04 | P0 | V030 含 7 列审计字段，无 IF NOT EXISTS |
| TC-30-05 | P0 | DataChangeInterceptor 无 security 包 import（DAG 合规） |
| TC-30-06 | P0 | DataChangeLogController 有 @PreAuthorize |
| TC-30-07 | P0 | LogCleanupJob 有 @DisallowConcurrentExecution |
| TC-30-08 | P1 | 标注 @AuditChange 的 Mapper 执行 UPDATE 后，sys_data_change_log 有对应记录 |

完整用例见 [spec/tests/phase-30-audit.tests.yml](../tests/phase-30-audit.tests.yml)

## 关键约束

- DataChangeInterceptor 在 data 模块，禁止 import security 包（DAG 合规）
- 异步写入使用 @Async，复用 LogAsyncConfig 已有线程池，禁止新建线程池
- V030 含 7 列审计字段，无 IF NOT EXISTS
- LogCleanupJob 必须标注 `@DisallowConcurrentExecution`
- DataChangeLogController 必须标注 `@PreAuthorize("hasAuthority('system:audit:list')")`

## 验收条件

1. V030 含 7 列审计字段，无 IF NOT EXISTS
2. DataChangeInterceptor 无 security 包 import（DAG 合规）
3. DataChangeLogController 有 @PreAuthorize("hasAuthority('system:audit:list')")
4. LogCleanupJob 有 @DisallowConcurrentExecution
5. 编译通过（mvn clean compile -q）
