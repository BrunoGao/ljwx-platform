---
phase: 50
title: "消息中台 - 模板管理 (Message Center - Template)"
targets:
  backend: true
  frontend: true
depends_on: [49]
bundle_with: [51]
---
# Phase 50 — 消息中台 - 模板管理

| 项目 | 值 |
|-----|---|
| Phase | 50 |
| 优先级 | 🟡 **P1** |

## 功能概述

实现消息模板管理,支持:
1. 模板 CRUD
2. 变量替换
3. 多渠道支持
4. 模板版本

## 数据库契约

### msg_template

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| template_code | VARCHAR(50) | UK, 模板编码 |
| template_name | VARCHAR(100) | |
| template_type | VARCHAR(20) | INBOX/EMAIL/SMS |
| subject | VARCHAR(200) | 邮件主题 |
| content | TEXT | 模板内容 |
| variables | TEXT | JSON 数组, 变量列表 |
| status | VARCHAR(20) | ENABLED/DISABLED |
| + 7 审计字段 | | |

### Flyway: V050__create_msg_template.sql

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/messages/templates | system:message:template:add |
| PUT | /api/v1/messages/templates/{id} | system:message:template:edit |
| DELETE | /api/v1/messages/templates/{id} | system:message:template:delete |
| GET | /api/v1/messages/templates/{id} | system:message:template:query |
| GET | /api/v1/messages/templates | system:message:template:list |

## 业务规则

- BL-50-01: 模板变量 → ${variable_name} 格式
- BL-50-02: 变量替换 → 运行时替换
- BL-50-03: 模板类型 → INBOX/EMAIL/SMS
- BL-50-04: 模板状态 → ENABLED/DISABLED

## 验收条件

- AC-01: 模板 CRUD 正常
- AC-02: 变量替换正确
- AC-03: 多渠道支持
- AC-04: 模板版本管理
