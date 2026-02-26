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
# Phase 7 — Quartz 调度集成 (Quartz Integration)

| 项目 | 值 |
|-----|---|
| Phase | 7 |
| 模块 | ljwx-platform-app |
| Feature | F-007 (定时任务调度) |
| 前置依赖 | Phase 5 (App Skeleton) |
| 测试契约 | `spec/tests/phase-07-quartz.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §Quartz 调度
- `spec/03-api.md` — §Jobs 路由
- `spec/04-database.md` — V010、V011
- `spec/08-output-rules.md`

---

## 数据库契约

### V010__create_quartz_tables.sql（Quartz 标准表）

| 表名 | 说明 | 审计字段 |
|------|------|----------|
| qrtz_job_details | Job 定义 | ❌ 无 |
| qrtz_triggers | 触发器 | ❌ 无 |
| qrtz_simple_triggers | 简单触发器 | ❌ 无 |
| qrtz_cron_triggers | Cron 触发器 | ❌ 无 |
| qrtz_blob_triggers | Blob 触发器 | ❌ 无 |
| qrtz_calendars | 日历 | ❌ 无 |
| qrtz_paused_trigger_grps | 暂停的触发器组 | ❌ 无 |
| qrtz_fired_triggers | 已触发的触发器 | ❌ 无 |
| qrtz_scheduler_state | 调度器状态 | ❌ 无 |
| qrtz_locks | 锁 | ❌ 无 |

**关键约束**：
- 使用 Quartz 官方 PostgreSQL DDL
- 表名前缀：`qrtz_`（小写）
- **禁止**：审计字段、IF NOT EXISTS

### V011__create_sys_job.sql（业务表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK | 雪花 ID |
| job_name | VARCHAR(100) | NOT NULL | 任务名称 |
| job_group | VARCHAR(100) | NOT NULL | 任务组（TENANT_{tenantId}） |
| bean_name | VARCHAR(200) | NOT NULL | Spring Bean 名称 |
| method_name | VARCHAR(100) | NOT NULL | 方法名 |
| params | TEXT | NULL | 参数（JSON） |
| cron_expression | VARCHAR(100) | NOT NULL | Cron 表达式 |
| status | SMALLINT | NOT NULL | 状态（0=暂停, 1=运行） |
| remark | VARCHAR(500) | NULL | 备注 |
| **审计字段** | | | **7 列** |

---

## API 契约

### JobController

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/jobs | system:job:list | 分页查询任务 |
| GET | /api/v1/jobs/{id} | system:job:detail | 查询任务详情 |
| POST | /api/v1/jobs | system:job:create | 创建任务 |
| PUT | /api/v1/jobs/{id} | system:job:update | 更新任务 |
| DELETE | /api/v1/jobs/{id} | system:job:delete | 删除任务 |
| POST | /api/v1/jobs/{id}/run | system:job:run | 立即执行任务 |
| POST | /api/v1/jobs/{id}/pause | system:job:pause | 暂停任务 |
| POST | /api/v1/jobs/{id}/resume | system:job:resume | 恢复任务 |

---

## DTO / VO 契约

### JobCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| jobName | String | @NotBlank, @Size(max=100) | 任务名称 |
| beanName | String | @NotBlank, @Size(max=200) | Bean 名称 |
| methodName | String | @NotBlank, @Size(max=100) | 方法名 |
| params | String | @Size(max=2000) | 参数（JSON） |
| cronExpression | String | @NotBlank, @Pattern(cron) | Cron 表达式 |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`, `tenantId`, `jobGroup`, `createdBy`, `createdTime`, `updatedBy`, `updatedTime`, `deleted`, `version`

### JobVO

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 任务 ID |
| jobName | String | 任务名称 |
| jobGroup | String | 任务组 |
| beanName | String | Bean 名称 |
| methodName | String | 方法名 |
| params | String | 参数 |
| cronExpression | String | Cron 表达式 |
| status | Integer | 状态 |
| remark | String | 备注 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

---

## 业务规则

- **BL-07-01**：V010 使用 Quartz 官方 DDL，**禁止**添加审计字段
- **BL-07-02**：V011 sys_job 表**必须**包含 7 列审计字段
- **BL-07-03**：JobKey 格式：`name="{jobId}", group="TENANT_{tenantId}"`，实现 per-tenant 隔离
- **BL-07-04**：创建任务时，jobGroup 由后端自动设置为 `TENANT_{tenantId}`，前端禁止传递
- **BL-07-05**：Cron 表达式必须通过 `CronExpression.isValidExpression()` 校验
- **BL-07-06**：任务执行失败不影响调度器运行，异常记录到日志

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-07-quartz.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-07-01 | 无 Token → 401 | P0 |
| TC-07-02 | 无权限 → 403 | P0 |
| TC-07-03 | 创建任务成功 | P0 |
| TC-07-04 | 租户 A 查不到租户 B 的任务 | P0 |
| TC-07-05 | 立即执行任务成功 | P0 |
| TC-07-06 | 暂停/恢复任务成功 | P0 |
| TC-07-07 | 删除任务后软删除 | P0 |
| TC-07-08 | 无效 Cron 表达式 → 400 | P0 |

---

## 验收条件

- **AC-01**：V010 包含 Quartz 标准 10 张表，无审计字段，无 IF NOT EXISTS
- **AC-02**：V011 sys_job 表包含 7 列审计字段
- **AC-03**：JobController 所有方法有 @PreAuthorize，权限字符串匹配 spec/03-api.md
- **AC-04**：JobKey group 格式为 `TENANT_{tenantId}`，实现 per-tenant 隔离
- **AC-05**：Cron 表达式校验生效
- **AC-06**：`./mvnw compile -pl ljwx-platform-app` 通过

---

## 关键约束

- 禁止：Quartz 表添加审计字段 · IF NOT EXISTS · jobGroup 由前端传递
- Quartz 表名前缀：`qrtz_`（小写）
- per-tenant 隔离：JobKey group = `TENANT_{tenantId}`

## 可 Bundle

可与 Phase 8 一起执行。
