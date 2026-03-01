---
phase: 48
title: "开放 API 管理 - 密钥管理 (Open API - Secret Management)"
targets:
  backend: true
  frontend: true
depends_on: [47]
bundle_with: [47]
---
# Phase 48 — 开放 API 管理 - 密钥管理

| 项目 | 值 |
|-----|---|
| Phase | 48 |
| 优先级 | 🟡 **P1** |

## 功能概述

实现开放 API 密钥管理,支持:
1. 密钥生成
2. 密钥轮换
3. HMAC 签名验证
4. nonce 防重放

## 数据库契约

### open_app_secret

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| app_id | BIGINT | FK → open_app.id |
| secret_key | VARCHAR(128) | 加密存储 |
| secret_version | INT | 版本号 |
| status | VARCHAR(20) | ACTIVE/EXPIRED |
| expire_time | TIMESTAMP | |
| + 7 审计字段 | | |

### Flyway: V048__create_open_app_secret.sql

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/open-api/apps/{appId}/secrets | system:openApi:secret:add |
| PUT | /api/v1/open-api/apps/{appId}/secrets/{id}/rotate | system:openApi:secret:edit |
| DELETE | /api/v1/open-api/apps/{appId}/secrets/{id} | system:openApi:secret:delete |
| GET | /api/v1/open-api/apps/{appId}/secrets | system:openApi:secret:list |

## 业务规则

- BL-48-01: 密钥生成 → 256-bit 随机密钥
- BL-48-02: 密钥轮换 → 旧密钥标记 EXPIRED
- BL-48-03: HMAC 签名 → SHA256(app_key + timestamp + nonce + body + secret_key)
- BL-48-04: nonce 防重放 → Redis 存储 5 分钟

## 验收条件

- AC-01: 密钥生成安全
- AC-02: 密钥轮换正常
- AC-03: HMAC 签名验证通过
- AC-04: nonce 防重放生效
