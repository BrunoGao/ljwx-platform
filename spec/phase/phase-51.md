---
phase: 51
title: "消息中台 - 消息发送 (Message Center - Sending)"
targets:
  backend: true
  frontend: true
depends_on: [50]
bundle_with: [50]
---
# Phase 51 — 消息中台 - 消息发送

| 项目 | 值 |
|-----|---|
| Phase | 51 |
| 优先级 | 🟡 **P1** |

## 功能概述

实现消息发送功能,支持:
1. 站内信
2. 邮件发送
3. 短信发送
4. 消息记录

## 数据库契约

### msg_record

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| template_id | BIGINT | FK → msg_template.id |
| message_type | VARCHAR(20) | INBOX/EMAIL/SMS |
| receiver_id | BIGINT | 接收用户 ID |
| receiver_address | VARCHAR(200) | 邮箱/手机号 |
| subject | VARCHAR(200) | |
| content | TEXT | |
| send_status | VARCHAR(20) | PENDING/SUCCESS/FAILURE |
| send_time | TIMESTAMP | |
| error_message | TEXT | |
| + 7 审计字段 | | |

### msg_user_inbox

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| user_id | BIGINT | FK → sys_user.id |
| message_id | BIGINT | FK → msg_record.id |
| title | VARCHAR(200) | |
| content | TEXT | |
| is_read | BOOLEAN | |
| read_time | TIMESTAMP | |
| + 7 审计字段 | | |

### Flyway: V051__create_msg_record_and_inbox.sql

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/messages/send | system:message:send |
| GET | /api/v1/messages/records | system:message:record:list |
| GET | /api/v1/messages/inbox | system:message:inbox:list |
| PUT | /api/v1/messages/inbox/{id}/read | system:message:inbox:read |

## 业务规则

- BL-51-01: 消息发送 → 异步处理 → 记录日志
- BL-51-02: 站内信 → 写入 msg_user_inbox
- BL-51-03: 邮件/短信 → 调用第三方服务
- BL-51-04: 发送失败 → 重试 3 次

## 验收条件

- AC-01: 站内信发送正常
- AC-02: 邮件发送成功
- AC-03: 短信发送成功
- AC-04: 消息记录完整
