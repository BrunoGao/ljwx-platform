---
phase: 53
title: "流程引擎 (简化版) (Workflow Engine - Simplified)"
targets:
  backend: true
  frontend: true
depends_on: [52]
bundle_with: []
---
# Phase 53 — 流程引擎 (简化版)

| 项目 | 值 |
|-----|---|
| Phase | 53 |
| 优先级 | 🟡 **P1** |

## 功能概述

实现简化版流程引擎,支持:
1. 流程定义
2. 流程实例
3. 任务管理
4. 审批流

## 数据库契约

### wf_definition

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| flow_key | VARCHAR(50) | UK, 流程标识 |
| flow_name | VARCHAR(100) | |
| flow_version | INT | 版本号 |
| flow_config | TEXT | JSON, 流程配置 |
| status | VARCHAR(20) | DRAFT/PUBLISHED/ARCHIVED |
| + 7 审计字段 | | |

### wf_instance

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| definition_id | BIGINT | FK → wf_definition.id |
| business_key | VARCHAR(100) | 业务主键 |
| business_type | VARCHAR(50) | 业务类型 |
| initiator_id | BIGINT | 发起人 |
| current_node | VARCHAR(50) | 当前节点 |
| status | VARCHAR(20) | RUNNING/COMPLETED/REJECTED/CANCELLED |
| start_time | TIMESTAMP | |
| end_time | TIMESTAMP | |
| + 7 审计字段 | | |

### wf_task

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| instance_id | BIGINT | FK → wf_instance.id |
| task_name | VARCHAR(100) | |
| task_type | VARCHAR(20) | APPROVAL/NOTIFY |
| assignee_id | BIGINT | 处理人 |
| status | VARCHAR(20) | PENDING/APPROVED/REJECTED |
| comment | TEXT | 审批意见 |
| handle_time | TIMESTAMP | |
| + 7 审计字段 | | |

### wf_history

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| instance_id | BIGINT | FK → wf_instance.id |
| task_id | BIGINT | FK → wf_task.id |
| action | VARCHAR(20) | START/APPROVE/REJECT/CANCEL |
| operator_id | BIGINT | 操作人 |
| comment | TEXT | 操作意见 |
| + 7 审计字段 | | |

### Flyway: V053__create_workflow.sql

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

- BL-53-01: 流程定义 → JSON 配置 → 节点 + 连线
- BL-53-02: 流程实例 → 启动流程 → 创建任务
- BL-53-03: 任务处理 → 审批/拒绝 → 流转下一节点
- BL-53-04: 可见性模型 → 6 级 (ADR-0008)

## 验收条件

- AC-01: 流程定义正常
- AC-02: 流程实例创建成功
- AC-03: 任务流转正确
- AC-04: 审批流程完整
