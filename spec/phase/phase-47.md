---
phase: 47
title: "开放 API 管理 - 应用管理 (Open API - App Management)"
targets:
  backend: true
  frontend: true
depends_on: [46]
bundle_with: [48]
---
# Phase 47 — 开放 API 管理 - 应用管理

| 项目 | 值 |
|-----|---|
| Phase | 47 |
| 优先级 | 🟡 **P1** |

## 功能概述

实现开放 API 应用管理,支持:
1. 应用注册
2. 密钥管理
3. HMAC 认证
4. 限流配置

## 数据库契约

### open_app

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| app_key | VARCHAR(64) | UK, 应用标识 |
| app_name | VARCHAR(100) | |
| app_type | VARCHAR(20) | INTERNAL/EXTERNAL |
| status | VARCHAR(20) | ENABLED/DISABLED |
| rate_limit | INT | 每秒请求数 |
| ip_whitelist | TEXT | JSON 数组 |
| expire_time | TIMESTAMP | |
| + 7 审计字段 | | |

### Flyway: V047__create_open_app.sql

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/open-api/apps | system:openApi:app:add |
| PUT | /api/v1/open-api/apps/{id} | system:openApi:app:edit |
| DELETE | /api/v1/open-api/apps/{id} | system:openApi:app:delete |
| GET | /api/v1/open-api/apps/{id} | system:openApi:app:query |
| GET | /api/v1/open-api/apps | system:openApi:app:list |

## 业务规则

- BL-47-01: 应用创建 → 自动生成 app_key
- BL-47-02: 应用状态 → ENABLED/DISABLED
- BL-47-03: 限流配置 → 每秒请求数
- BL-47-04: IP 白名单 → JSON 数组存储

## 验收条件

- AC-01: 应用 CRUD 正常
- AC-02: app_key 唯一性保证
- AC-03: 限流配置生效
- AC-04: IP 白名单验证
