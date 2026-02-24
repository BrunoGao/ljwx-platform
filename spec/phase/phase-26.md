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

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Menus、§Depts、§Profile、§LoginLog、§OnlineUsers、§Monitor
- `spec/08-output-rules.md`

## 任务

为 Phase 20-25 新增的后端 Controller 编写集成测试，复用 Phase 18 已有的测试基础设施（Testcontainers PostgreSQL、JWT 工具方法）。

每个测试类覆盖：
1. 未认证请求返回 401
2. 无权限请求返回 403
3. 正常 CRUD 流程（创建 → 查询 → 更新 → 删除）
4. 参数校验（缺少必填字段返回 400）

**MenuControllerIT**：测试树形查询 `/api/v1/menus/tree` 返回嵌套结构。

**DeptControllerIT**：测试部门树 `/api/v1/depts/tree`。

**ProfileControllerIT**：测试修改密码（旧密码错误返回 400）。

**LoginLogControllerIT**：测试登录后日志自动写入。

**OnlineUserControllerIT**：测试强制下线后 token 失效。

**MonitorControllerIT**：测试 `/api/v1/monitor/server` 返回非空数据。

## 关键约束

- 使用 Testcontainers（版本由 BOM 管理）
- 测试数据库与生产数据库隔离
- 无 TypeScript 相关（纯后端 Phase）

## Phase-Local Manifest

```
ljwx-platform-app/src/test/java/com/ljwx/platform/app/MenuControllerIT.java
ljwx-platform-app/src/test/java/com/ljwx/platform/app/DeptControllerIT.java
ljwx-platform-app/src/test/java/com/ljwx/platform/app/ProfileControllerIT.java
ljwx-platform-app/src/test/java/com/ljwx/platform/app/LoginLogControllerIT.java
ljwx-platform-app/src/test/java/com/ljwx/platform/app/OnlineUserControllerIT.java
ljwx-platform-app/src/test/java/com/ljwx/platform/app/MonitorControllerIT.java
```

## 验收条件

1. `mvn test -f pom.xml` 全部通过
2. 每个 IT 类至少 4 个测试方法
3. 无硬编码数据库连接（全部走 Testcontainers）
