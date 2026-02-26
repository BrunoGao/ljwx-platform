---
phase: 26
title: "Integration Tests Phase 2"
targets:
  backend: true
  frontend: false
depends_on: [25]
bundle_with: []
scope:
  - "ljwx-platform-app/src/test/java/com/ljwx/platform/app/MenuControllerIT.java"
  - "ljwx-platform-app/src/test/java/com/ljwx/platform/app/DeptControllerIT.java"
  - "ljwx-platform-app/src/test/java/com/ljwx/platform/app/ProfileControllerIT.java"
  - "ljwx-platform-app/src/test/java/com/ljwx/platform/app/LoginLogControllerIT.java"
  - "ljwx-platform-app/src/test/java/com/ljwx/platform/app/OnlineUserControllerIT.java"
  - "ljwx-platform-app/src/test/java/com/ljwx/platform/app/MonitorControllerIT.java"
---
# Phase 26: Integration Tests (Phase 2 Features)

## Overview

| 属性 | 值 |
|------|-----|
| Phase | 26 |
| 模块 | ljwx-platform-app（test scope） |
| Feature | 为 Phase 20-25 新增 Controller 编写集成测试 |
| 前置依赖 | Phase 25 |
| 测试契约 | N/A — 本 Phase 即为测试实现 |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Menus、§Depts、§Profile、§LoginLog、§OnlineUsers、§Monitor
- `spec/08-output-rules.md`

## 测试覆盖契约

| IT 类 | 覆盖接口 | 最少测试方法数 |
|-------|---------|--------------|
| MenuControllerIT | GET /api/v1/menus、POST /api/v1/menus、PUT /api/v1/menus/{id}、DELETE /api/v1/menus/{id}、GET /api/v1/menus/tree | 6 |
| DeptControllerIT | GET /api/v1/depts、POST /api/v1/depts、PUT /api/v1/depts/{id}、DELETE /api/v1/depts/{id}、GET /api/v1/depts/tree | 6 |
| ProfileControllerIT | GET /api/v1/profile、PUT /api/v1/profile、PUT /api/v1/profile/password（旧密码错误返回 400） | 4 |
| LoginLogControllerIT | GET /api/v1/login-logs（登录后自动写入条目，日志列表非空） | 4 |
| OnlineUserControllerIT | GET /api/v1/online-users、DELETE /api/v1/online-users/{tokenId}（强制下线后该 token 返回 401） | 4 |
| MonitorControllerIT | GET /api/v1/monitor/server（data 非空）、GET /api/v1/monitor/jvm、GET /api/v1/monitor/cache | 4 |

每个测试类必须覆盖：
1. 未认证请求返回 401
2. 无权限请求返回 403
3. 核心正向流程（参见上表）
4. 参数校验（缺少必填字段返回 400）

> 本 Phase 即为测试实现，验证方式：`mvn test -f pom.xml` 全部通过

## 关键约束

- 使用 Testcontainers（版本由 BOM 管理），复用 Phase 18 测试基础设施
- 测试数据库与生产数据库严格隔离，禁止硬编码数据库连接串
- 无 TypeScript 相关（纯后端 Phase）

## 验收条件

1. `mvn test -f pom.xml` 全部通过
2. 每个 IT 类至少 4 个测试方法
3. 无硬编码数据库连接（全部走 Testcontainers）
