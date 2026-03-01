---
phase: 52
title: "敏感数据加密 (Sensitive Data Encryption)"
targets:
  backend: true
  frontend: false
depends_on: [51]
bundle_with: []
---
# Phase 52 — 敏感数据加密

| 项目 | 值 |
|-----|---|
| Phase | 52 |
| 优先级 | 🟡 **P1** |

## 功能概述

实现敏感数据加密,支持:
1. 字段级加密
2. 密钥管理
3. 密钥轮换
4. 加密策略

## 数据库契约

### sys_encrypt_key

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| key_name | VARCHAR(50) | UK, 密钥名称 |
| key_value | VARCHAR(500) | 加密存储 |
| key_version | INT | 版本号 |
| algorithm | VARCHAR(20) | AES256/SM4 |
| status | VARCHAR(20) | ACTIVE/EXPIRED |
| expire_time | TIMESTAMP | |
| + 7 审计字段 | | |

### Flyway: V052__create_encrypt_key.sql

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/encrypt/keys | system:encrypt:key:add |
| PUT | /api/v1/encrypt/keys/{id}/rotate | system:encrypt:key:edit |
| DELETE | /api/v1/encrypt/keys/{id} | system:encrypt:key:delete |
| GET | /api/v1/encrypt/keys/{id} | system:encrypt:key:query |
| GET | /api/v1/encrypt/keys | system:encrypt:key:list |

## 业务规则

- BL-52-01: 密钥生成 → 256-bit 随机密钥
- BL-52-02: 密钥轮换 → 旧密钥标记 EXPIRED
- BL-52-03: 字段加密 → AES-256-GCM
- BL-52-04: 加密字段 → 手机号、身份证、银行卡

## 验收条件

- AC-01: 密钥管理正常
- AC-02: 密钥轮换成功
- AC-03: 字段加密正确
- AC-04: 解密功能正常
