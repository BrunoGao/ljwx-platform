---
phase: 45
title: "任务执行日志 (Task Execution Log)"
targets:
  backend: true
  frontend: true
depends_on: [44]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V045__create_task_execution_log.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/TaskExecutionLog.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/TaskExecutionLogMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/TaskExecutionLogAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/TaskExecutionLogController.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/task/TaskExecutionLogger.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/TaskExecutionLogQueryDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/TaskExecutionLogVO.java"
  - "ljwx-platform-admin/src/api/taskLog.ts"
  - "ljwx-platform-admin/src/views/system/task-log/index.vue"
---
# Phase 45 — 任务执行日志

| 项目 | 值 |
|-----|---|
| Phase | 45 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L2-D06-F01 |
| 前置依赖 | Phase 44 (角色-自定义数据范围) |
| 测试契约 | `spec/tests/phase-45-task-log.tests.yml` |
| 优先级 | 🟡 **P1 - 定时任务可观测性** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §任务执行日志表
- `spec/03-api.md` — §任务执行日志 API
- `spec/01-constraints.md` — §审计字段
- `spec/registry/observability.yml` — §Loki 日志
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 当前系统缺少定时任务执行日志,无法追踪任务执行历史、排查任务失败原因。

**解决方案**: 实现任务执行日志功能,支持:
1. 记录任务执行开始/结束时间
2. 记录任务执行状态（成功/失败）
3. 记录任务执行耗时
4. 记录任务执行结果/错误信息
5. 支持日志查询和统计
6. 支持日志清理（保留 30 天）

---

## 数据库契约

### 表结构：sys_task_execution_log

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| task_name | VARCHAR(100) | NOT NULL, INDEX | 任务名称 |
| task_group | VARCHAR(50) | NOT NULL, INDEX | 任务分组 |
| task_params | TEXT | | 任务参数 |
| status | VARCHAR(20) | NOT NULL, INDEX | SUCCESS / FAILURE / RUNNING |
| start_time | TIMESTAMP | NOT NULL, INDEX | 开始时间 |
| end_time | TIMESTAMP | | 结束时间 |
| duration | INT | | 执行耗时（毫秒） |
| result | TEXT | | 执行结果 |
| error_message | TEXT | | 错误信息 |
| error_stack | TEXT | | 错误堆栈 |
| server_ip | VARCHAR(50) | | 服务器 IP |
| server_name | VARCHAR(100) | | 服务器名称 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_task_name_start_time` (task_name, start_time DESC)
- `idx_status_start_time` (status, start_time DESC)
- `idx_tenant_id` (tenant_id)
- `idx_start_time` (start_time DESC)

**分区策略**: 按月分区 (start_time)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V045__create_task_execution_log.sql` | 建表 + 索引 + 分区 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|---------|
| GET | /api/v1/task-logs | system:taskLog:list | — (Query Parameters) | Result<Page<TaskExecutionLogVO>> | 查询列表（分页） |
| GET | /api/v1/task-logs/{id} | system:taskLog:query | — | Result<TaskExecutionLogVO> | 查询详情 |
| DELETE | /api/v1/task-logs/{id} | system:taskLog:delete | — | Result<Void> | 删除日志（软删） |
| POST | /api/v1/task-logs/clean | system:taskLog:clean | — | Result<Integer> | 清理历史日志（30 天前） |
| GET | /api/v1/task-logs/stats | system:taskLog:stats | — | Result<TaskLogStatsVO> | 任务执行统计 |

---

## DTO / VO 契约

### TaskExecutionLogQueryDTO（查询条件）

| 字段 | 类型 | 说明 |
|------|------|------|
| taskName | String | 任务名称（模糊） |
| taskGroup | String | 任务分组 |
| status | String | 状态 |
| startTimeBegin | LocalDateTime | 开始时间（起） |
| startTimeEnd | LocalDateTime | 开始时间（止） |

**禁止字段**：`tenantId`（框架自动注入）

### TaskExecutionLogVO（响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| taskName | String | 任务名称 |
| taskGroup | String | 任务分组 |
| taskParams | String | 任务参数 |
| status | String | 状态 |
| startTime | LocalDateTime | 开始时间 |
| endTime | LocalDateTime | 结束时间 |
| duration | Integer | 执行耗时（毫秒） |
| result | String | 执行结果 |
| errorMessage | String | 错误信息 |
| errorStack | String | 错误堆栈 |
| serverIp | String | 服务器 IP |
| serverName | String | 服务器名称 |
| createdTime | LocalDateTime | 创建时间 |

**禁止字段**：`tenantId`、`deleted`、`createdBy`、`updatedBy`、`updatedTime`、`version`

### TaskLogStatsVO（统计响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| totalCount | Long | 总执行次数 |
| successCount | Long | 成功次数 |
| failureCount | Long | 失败次数 |
| avgDuration | Integer | 平均耗时（毫秒） |
| maxDuration | Integer | 最大耗时（毫秒） |
| minDuration | Integer | 最小耗时（毫秒） |

---

## 业务规则

> 格式：BL-45-{序号}：[条件] → [动作] → [结果/异常]

- **BL-45-01**：任务开始执行 → 插入日志记录（status=RUNNING） → 记录 start_time
- **BL-45-02**：任务执行成功 → 更新日志记录（status=SUCCESS） → 记录 end_time, duration, result
- **BL-45-03**：任务执行失败 → 更新日志记录（status=FAILURE） → 记录 end_time, duration, error_message, error_stack
- **BL-45-04**：任务执行超时 → 更新日志记录（status=FAILURE） → error_message="任务执行超时"
- **BL-45-05**：定期清理 → 删除 30 天前的日志 → 保留最近 30 天
- **BL-45-06**：查询日志 → 按 start_time DESC 排序 → 最新日志在前
- **BL-45-07**：统计任务执行 → 按 task_name 分组 → 计算成功率、平均耗时
- **BL-45-08**：日志写入失败 → 不影响任务执行 → 记录到 Loki 日志

---

## 核心组件契约

### TaskExecutionLogger

```java
@Component
@RequiredArgsConstructor
public class TaskExecutionLogger {

    private final TaskExecutionLogRepository taskExecutionLogRepository;

    /**
     * 记录任务开始
     */
    public Long logStart(String taskName, String taskGroup, String taskParams) {
        TaskExecutionLog log = TaskExecutionLog.builder()
            .taskName(taskName)
            .taskGroup(taskGroup)
            .taskParams(taskParams)
            .status("RUNNING")
            .startTime(LocalDateTime.now())
            .serverIp(getServerIp())
            .serverName(getServerName())
            .build();

        taskExecutionLogRepository.insert(log);
        return log.getId();
    }

    /**
     * 记录任务成功
     */
    public void logSuccess(Long logId, String result) {
        TaskExecutionLog log = taskExecutionLogRepository.findById(logId);
        if (log == null) return;

        log.setStatus("SUCCESS");
        log.setEndTime(LocalDateTime.now());
        log.setDuration(calculateDuration(log.getStartTime(), log.getEndTime()));
        log.setResult(result);

        taskExecutionLogRepository.update(log);
    }

    /**
     * 记录任务失败
     */
    public void logFailure(Long logId, Exception exception) {
        TaskExecutionLog log = taskExecutionLogRepository.findById(logId);
        if (log == null) return;

        log.setStatus("FAILURE");
        log.setEndTime(LocalDateTime.now());
        log.setDuration(calculateDuration(log.getStartTime(), log.getEndTime()));
        log.setErrorMessage(exception.getMessage());
        log.setErrorStack(getStackTrace(exception));

        taskExecutionLogRepository.update(log);
    }

    private int calculateDuration(LocalDateTime start, LocalDateTime end) {
        return (int) Duration.between(start, end).toMillis();
    }

    private String getStackTrace(Exception exception) {
        StringWriter sw = new StringWriter();
        exception.printStackTrace(new PrintWriter(sw));
        return sw.toString();
    }
}
```

### 任务执行示例

```java
@Scheduled(cron = "0 0 2 * * ?")
public void cleanExpiredData() {
    Long logId = null;
    try {
        // 1. 记录任务开始
        logId = taskExecutionLogger.logStart("cleanExpiredData", "SYSTEM", null);

        // 2. 执行任务
        int count = dataCleanService.cleanExpiredData();

        // 3. 记录任务成功
        taskExecutionLogger.logSuccess(logId, "清理 " + count + " 条过期数据");

    } catch (Exception e) {
        // 4. 记录任务失败
        if (logId != null) {
            taskExecutionLogger.logFailure(logId, e);
        }
        log.error("清理过期数据失败", e);
    }
}
```

---

## 定期清理

```java
@Scheduled(cron = "0 0 3 * * ?")  // 每天凌晨 3 点
public void cleanOldTaskLogs() {
    LocalDateTime threshold = LocalDateTime.now().minusDays(30);
    int count = taskExecutionLogRepository.deleteByStartTimeBefore(threshold);
    log.info("清理 {} 条 30 天前的任务执行日志", count);
}
```

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-45-task-log.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-45-01 | 无 Token → 401 | P0 |
| TC-45-02 | 无权限 → 403 | P0 |
| TC-45-03 | 查询任务日志列表 | P0 |
| TC-45-04 | 查询任务日志详情 | P0 |
| TC-45-05 | 任务执行成功记录日志 | P0 |
| TC-45-06 | 任务执行失败记录日志 | P0 |
| TC-45-07 | 清理历史日志 | P0 |
| TC-45-08 | 任务执行统计 | P1 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`
- **AC-03**：DTO 不含禁止字段
- **AC-04**：任务开始时正确记录日志
- **AC-05**：任务成功时正确更新日志
- **AC-06**：任务失败时正确更新日志
- **AC-07**：定期清理 30 天前的日志
- **AC-08**：任务执行统计正确
- **AC-09**：编译通过,前端 `type-check` 通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:taskLog:list')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · 在 DTO 中声明禁止字段
- 日志写入失败：不影响任务执行,记录到 Loki
- 日志保留：30 天,定期清理
- 分区策略：按月分区,提升查询性能
- Loki labels：仅 app/env/level,禁止 tenantId/taskName
