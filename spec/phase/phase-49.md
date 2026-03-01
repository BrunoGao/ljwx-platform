---
phase: 49
title: "Webhook 事件推送 (Webhook Event Push)"
targets:
  backend: true
  frontend: true
depends_on: [48]
bundle_with: []
---
# Phase 49 — Webhook 事件推送

| 项目 | 值 |
|-----|---|
| Phase | 49 |
| 优先级 | 🟡 **P1** |

## 功能概述

实现 Webhook 事件推送,支持:
1. Webhook 配置
2. 事件订阅
3. 推送重试
4. 推送日志

## 数据库契约

### webhook_config

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| webhook_name | VARCHAR(100) | |
| webhook_url | VARCHAR(500) | |
| event_types | TEXT | JSON 数组 |
| secret_key | VARCHAR(128) | 签名密钥 |
| status | VARCHAR(20) | ENABLED/DISABLED |
| retry_count | INT | 重试次数 |
| timeout_seconds | INT | 超时时间 |
| + 7 审计字段 | | |

### webhook_log

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| webhook_id | BIGINT | FK → webhook_config.id |
| event_type | VARCHAR(50) | |
| event_data | TEXT | JSON |
| request_url | VARCHAR(500) | |
| request_headers | TEXT | JSON |
| request_body | TEXT | |
| response_status | INT | |
| response_body | TEXT | |
| retry_times | INT | |
| status | VARCHAR(20) | SUCCESS/FAILURE |
| error_message | TEXT | |
| + 7 审计字段 | | |

### Flyway: V049__create_webhook.sql

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/webhooks | system:webhook:add |
| PUT | /api/v1/webhooks/{id} | system:webhook:edit |
| DELETE | /api/v1/webhooks/{id} | system:webhook:delete |
| GET | /api/v1/webhooks/{id} | system:webhook:query |
| GET | /api/v1/webhooks | system:webhook:list |
| GET | /api/v1/webhooks/{id}/logs | system:webhook:log:list |

## 业务规则

- BL-49-01: 事件触发 → 异步推送 → 记录日志
- BL-49-02: 推送失败 → 指数退避重试 (1s, 2s, 4s, 8s, 16s)
- BL-49-03: 签名验证 → HMAC-SHA256(timestamp + body + secret_key)
- BL-49-04: 超时控制 → 默认 5 秒

## 验收条件

- AC-01: Webhook 配置正常
- AC-02: 事件推送成功
- AC-03: 重试机制生效
- AC-04: 推送日志完整
