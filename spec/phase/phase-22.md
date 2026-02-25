---
phase: 22
title: "Profile Login Log and Online Users"
targets:
  backend: true
  frontend: false
depends_on: [21]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V026__create_sys_login_log.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysLoginLog.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysLoginLogMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/LoginLogAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/LoginLogController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/LoginLogVO.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysLoginLogMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/ProfileController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/ProfileUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/PasswordUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/ProfileAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/OnlineUserController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/OnlineUserAppService.java"
---
# Phase 22: Profile, Login Log & Online Users

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Profile、§LoginLog、§OnlineUsers 路由
- `spec/04-database.md` — sys_login_log 表结构
- `spec/01-constraints.md` — §日志脱敏、§审计字段
- `spec/08-output-rules.md`

## 任务

### 1. 登录日志（V026 + Controller）

**表 sys_login_log**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| username | VARCHAR(64) NOT NULL | 登录用户名 |
| ip_address | VARCHAR(64) NOT NULL DEFAULT '' | 登录 IP |
| user_agent | VARCHAR(500) NOT NULL DEFAULT '' | User-Agent |
| status | SMALLINT NOT NULL DEFAULT 1 | 1=成功 0=失败 |
| message | VARCHAR(255) NOT NULL DEFAULT '' | 提示消息 |
| login_time | TIMESTAMPTZ NOT NULL DEFAULT NOW() | 登录时间 |
| + 7 列审计字段 | | |

AuthController 登录成功/失败时异步写入 sys_login_log（复用已有 LogAsyncConfig 线程池）。

API：`GET /api/v1/login-logs`（分页，权限 `system:log:login:list`）

### 2. 个人中心

API：`/api/v1/profile`

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/profile | 获取当前用户信息（无需 @PreAuthorize，已认证即可） |
| PUT | /api/v1/profile | 修改个人信息（昵称、邮箱、手机） |
| PUT | /api/v1/profile/password | 修改密码（需验证旧密码） |

- PasswordUpdateDTO：oldPassword, newPassword（不含 tenantId）
- 密码字段日志脱敏：`***`

### 3. 在线用户

基于 JWT 的无状态架构，在线用户通过 Token 黑名单机制实现强制下线：
- OnlineUserAppService 维护 Caffeine 缓存中的活跃 token 集合（key=jti，TTL=access token 过期时间）
- 登录时注册 token，登出时移除

API：

| 方法 | 路径 | 权限 |
|------|------|------|
| GET | /api/v1/online-users | `system:online:list` |
| DELETE | /api/v1/online-users/{tokenId} | `system:online:kickout`（强制下线） |

## 关键约束

- sys_login_log 含 7 列审计字段
- 登录日志异步写入，不阻塞登录响应
- ProfileController 的 GET/PUT 方法不需要 @PreAuthorize（已通过 JWT 认证），但需在 SecurityConfig 中配置 authenticated()

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V026__create_sys_login_log.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysLoginLog.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysLoginLogMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/LoginLogAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/LoginLogController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/LoginLogVO.java
ljwx-platform-app/src/main/resources/mapper/SysLoginLogMapper.xml
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/ProfileController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/ProfileUpdateDTO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/PasswordUpdateDTO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/ProfileAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/OnlineUserController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/OnlineUserAppService.java
```

## 验收条件

1. V026 含 7 列审计字段，无 IF NOT EXISTS
2. 登录日志异步写入（@Async）
3. 密码字段脱敏
4. 编译通过

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-22-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-22-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-22-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-22-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-22-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-22-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-22-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-22-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-22-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-22-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
