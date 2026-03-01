---
phase: 53
title: "流程引擎 (简化版) (Workflow Engine - Simplified)"
targets:
  backend: true
  frontend: true
depends_on: [52]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V053__create_workflow.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/WfDefinition.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/WfInstance.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/WfTask.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/WfHistory.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/WorkflowController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/WorkflowService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/WfDefinitionMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/WfInstanceMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/WfTaskMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/WfHistoryMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/WfDefinitionMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/WfInstanceMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/WfTaskMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/WfHistoryMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/WfDefinitionDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/WfInstanceDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/WfTaskDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/WfDefinitionVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/WfInstanceVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/WfTaskVO.java"
  - "ljwx-platform-web/src/views/workflow/definition/index.vue"
  - "ljwx-platform-web/src/views/workflow/instance/index.vue"
  - "ljwx-platform-web/src/views/workflow/task/index.vue"
  - "ljwx-platform-web/src/api/workflow/definition.ts"
  - "ljwx-platform-web/src/api/workflow/instance.ts"
  - "ljwx-platform-web/src/api/workflow/task.ts"
---
# Phase 53 — 流程引擎 (简化版)

| 项目 | 值 |
|-----|---|
| Phase | 53 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-web (前端) |
| Feature | L0-D07-F01 |
| 前置依赖 | Phase 52 (消息订阅管理) |
| 测试契约 | `spec/tests/phase-53-workflow.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §流程引擎表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

## 功能概述

实现简化版流程引擎,支持:
1. 流程定义
2. 流程实例
3. 任务管理
4. 审批流

## 数据库契约

### 表结构：wf_definition

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| flow_key | VARCHAR(50) | UK, NOT NULL | 流程标识 |
| flow_name | VARCHAR(100) | NOT NULL | 流程名称 |
| flow_version | INT | NOT NULL, DEFAULT 1 | 版本号 |
| flow_config | TEXT | NOT NULL | JSON, 流程配置 |
| status | VARCHAR(20) | NOT NULL, INDEX | DRAFT/PUBLISHED/ARCHIVED |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_flow_key_version` (flow_key, flow_version) UNIQUE
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)

### 表结构：wf_instance

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| definition_id | BIGINT | NOT NULL, INDEX | FK → wf_definition.id |
| business_key | VARCHAR(100) | NOT NULL, INDEX | 业务主键 |
| business_type | VARCHAR(50) | NOT NULL, INDEX | 业务类型 |
| initiator_id | BIGINT | NOT NULL | 发起人 |
| current_node | VARCHAR(50) | | 当前节点 |
| status | VARCHAR(20) | NOT NULL, INDEX | RUNNING/COMPLETED/REJECTED/CANCELLED |
| start_time | TIMESTAMP | NOT NULL | 开始时间 |
| end_time | TIMESTAMP | | 结束时间 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_definition_id` (definition_id)
- `idx_business` (business_type, business_key)
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)

### 表结构：wf_task

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| instance_id | BIGINT | NOT NULL, INDEX | FK → wf_instance.id |
| task_name | VARCHAR(100) | NOT NULL | 任务名称 |
| task_type | VARCHAR(20) | NOT NULL | APPROVAL/NOTIFY |
| assignee_id | BIGINT | NOT NULL, INDEX | 处理人 |
| status | VARCHAR(20) | NOT NULL, INDEX | PENDING/APPROVED/REJECTED |
| comment | TEXT | | 审批意见 |
| handle_time | TIMESTAMP | | 处理时间 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_instance_id` (instance_id)
- `idx_assignee_status` (assignee_id, status)
- `idx_tenant_id` (tenant_id)

### 表结构：wf_history

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| instance_id | BIGINT | NOT NULL, INDEX | FK → wf_instance.id |
| task_id | BIGINT | INDEX | FK → wf_task.id |
| action | VARCHAR(20) | NOT NULL | START/APPROVE/REJECT/CANCEL |
| operator_id | BIGINT | NOT NULL | 操作人 |
| comment | TEXT | | 操作意见 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_instance_id` (instance_id)
- `idx_task_id` (task_id)
- `idx_tenant_id` (tenant_id)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V053__create_workflow.sql` | 建表 + 索引 + 外键约束 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/workflows/definitions | system:workflow:definition:add |
| PUT | /api/v1/workflows/definitions/{id} | system:workflow:definition:edit |
| DELETE | /api/v1/workflows/definitions/{id} | system:workflow:definition:delete |
| GET | /api/v1/workflows/definitions | system:workflow:definition:list |
| POST | /api/v1/workflows/instances | system:workflow:instance:add |
| GET | /api/v1/workflows/instances/{id} | system:workflow:instance:query |
| GET | /api/v1/workflows/tasks/my | system:workflow:task:list |
| POST | /api/v1/workflows/tasks/{id}/approve | system:workflow:task:approve |
| POST | /api/v1/workflows/tasks/{id}/reject | system:workflow:task:reject |

## 业务规则

> 格式：BL-53-{序号}：[条件] → [动作] → [结果/异常]

- **BL-53-01**：创建流程定义 → 保存 JSON 配置（节点 + 连线） → 状态为 DRAFT
- **BL-53-02**：发布流程定义 → 更新状态为 PUBLISHED → 可用于创建实例
- **BL-53-03**：启动流程实例 → 创建 wf_instance + 首个 wf_task → 状态为 RUNNING
- **BL-53-04**：任务审批通过 → 更新任务状态为 APPROVED → 流转到下一节点
- **BL-53-05**：任务审批拒绝 → 更新任务状态为 REJECTED → 实例状态为 REJECTED
- **BL-53-06**：所有任务完成 → 更新实例状态为 COMPLETED → 记录结束时间
- **BL-53-07**：每次操作 → 记录到 wf_history → 保留审计轨迹
- **BL-53-08**：可见性模型 → 6 级 (ADR-0009) → 租户隔离

## 核心组件契约

### WfDefinition 实体

```java
@Data
@TableName("wf_definition")
public class WfDefinition extends BaseEntity {
    private String flowKey;
    private String flowName;
    private Integer flowVersion;
    private String flowConfig;  // JSON
    private String status;      // DRAFT / PUBLISHED / ARCHIVED
}
```

### WfInstance 实体

```java
@Data
@TableName("wf_instance")
public class WfInstance extends BaseEntity {
    private Long definitionId;
    private String businessKey;
    private String businessType;
    private Long initiatorId;
    private String currentNode;
    private String status;      // RUNNING / COMPLETED / REJECTED / CANCELLED
    private LocalDateTime startTime;
    private LocalDateTime endTime;
}
```

### WfTask 实体

```java
@Data
@TableName("wf_task")
public class WfTask extends BaseEntity {
    private Long instanceId;
    private String taskName;
    private String taskType;    // APPROVAL / NOTIFY
    private Long assigneeId;
    private String status;      // PENDING / APPROVED / REJECTED
    private String comment;
    private LocalDateTime handleTime;
}
```

### WfHistory 实体

```java
@Data
@TableName("wf_history")
public class WfHistory extends BaseEntity {
    private Long instanceId;
    private Long taskId;
    private String action;      // START / APPROVE / REJECT / CANCEL
    private Long operatorId;
    private String comment;
}
```

### WorkflowController

```java
@RestController
@RequestMapping("/api/v1/workflows")
@RequiredArgsConstructor
public class WorkflowController {

    @PostMapping("/definitions")
    @PreAuthorize("@ss.hasPermission('system:workflow:definition:add')")
    public R<Long> createDefinition(@Valid @RequestBody WfDefinitionDTO dto) {
        // 创建流程定义
    }

    @PutMapping("/definitions/{id}")
    @PreAuthorize("@ss.hasPermission('system:workflow:definition:edit')")
    public R<Void> updateDefinition(@PathVariable Long id, @Valid @RequestBody WfDefinitionDTO dto) {
        // 更新流程定义
    }

    @DeleteMapping("/definitions/{id}")
    @PreAuthorize("@ss.hasPermission('system:workflow:definition:delete')")
    public R<Void> deleteDefinition(@PathVariable Long id) {
        // 删除流程定义
    }

    @GetMapping("/definitions")
    @PreAuthorize("@ss.hasPermission('system:workflow:definition:list')")
    public R<PageResult<WfDefinitionVO>> listDefinitions(WfDefinitionQueryDTO query) {
        // 查询流程定义列表
    }

    @PostMapping("/instances")
    @PreAuthorize("@ss.hasPermission('system:workflow:instance:add')")
    public R<Long> startInstance(@Valid @RequestBody WfInstanceDTO dto) {
        // 启动流程实例
    }

    @GetMapping("/instances/{id}")
    @PreAuthorize("@ss.hasPermission('system:workflow:instance:query')")
    public R<WfInstanceVO> getInstance(@PathVariable Long id) {
        // 查询流程实例详情
    }

    @GetMapping("/tasks/my")
    @PreAuthorize("@ss.hasPermission('system:workflow:task:list')")
    public R<PageResult<WfTaskVO>> getMyTasks(WfTaskQueryDTO query) {
        // 查询我的待办任务
    }

    @PostMapping("/tasks/{id}/approve")
    @PreAuthorize("@ss.hasPermission('system:workflow:task:approve')")
    public R<Void> approveTask(@PathVariable Long id, @RequestBody WfTaskActionDTO dto) {
        // 审批通过
    }

    @PostMapping("/tasks/{id}/reject")
    @PreAuthorize("@ss.hasPermission('system:workflow:task:reject')")
    public R<Void> rejectTask(@PathVariable Long id, @RequestBody WfTaskActionDTO dto) {
        // 审批拒绝
    }
}
```

## 前端文件路径

| 文件 | 说明 |
|------|------|
| `ljwx-platform-web/src/views/workflow/definition/index.vue` | 流程定义管理页面 |
| `ljwx-platform-web/src/views/workflow/instance/index.vue` | 流程实例查询页面 |
| `ljwx-platform-web/src/views/workflow/task/index.vue` | 我的待办任务页面 |
| `ljwx-platform-web/src/api/workflow/definition.ts` | 流程定义 API |
| `ljwx-platform-web/src/api/workflow/instance.ts` | 流程实例 API |
| `ljwx-platform-web/src/api/workflow/task.ts` | 任务 API |

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：流程定义正常创建、发布、归档
- **AC-03**：流程实例启动成功,创建首个任务
- **AC-04**：任务审批流转正确,状态更新准确
- **AC-05**：审批历史完整记录,支持审计追溯
- **AC-06**：前端页面正常展示流程定义、实例、任务
- **AC-07**：编译通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 流程配置：使用 JSON 格式存储节点和连线
- 任务流转：审批通过后自动创建下一节点任务
- 历史记录：每次操作必须记录到 wf_history
- 禁止：在 DTO 中声明 `tenantId`
