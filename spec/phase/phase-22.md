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
# Phase 22 — Profile, Login Log & Online Users

| 项目 | 值 |
|-----|---|
| Phase | 22 |
| 模块 | ljwx-platform-app（后端 only） |
| Feature | 登录日志（V026）/ 个人中心 / 在线用户管理 |
| 前置依赖 | Phase 21 (Department Management) |
| 测试契约 | `spec/tests/phase-22-profile.tests.yml` |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Profile、§LoginLog、§OnlineUsers 路由
- `spec/04-database.md` — sys_login_log 表结构
- `spec/01-constraints.md` — §日志脱敏、§审计字段
- `spec/08-output-rules.md`

---

## 数据库契约

### 表结构：sys_login_log

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| username | VARCHAR(64) | NOT NULL | 登录用户名 |
| ip_address | VARCHAR(64) | NOT NULL, DEFAULT '' | 登录 IP |
| user_agent | VARCHAR(500) | NOT NULL, DEFAULT '' | User-Agent |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 1=成功 0=失败 |
| message | VARCHAR(255) | NOT NULL, DEFAULT '' | 提示消息 |
| login_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 登录时间 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

> 7 列审计字段（tenant_id, created_by, created_time, updated_by, updated_time, deleted, version）均 NOT NULL + DEFAULT，禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V026__create_sys_login_log.sql` | 建表 + 索引（idx_login_log_tenant_time(tenant_id, login_time)） |

禁止：`IF NOT EXISTS`、建表文件中混 DML。

---

## API 契约

### 登录日志

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/login-logs | system:log:login:list | — | Result<PageResult\<LoginLogVO\>> | 分页查询 |

### 个人中心

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/profile | 无 @PreAuthorize（SecurityConfig 配置 authenticated()） | — | Result\<UserVO\> | 获取当前用户信息 |
| PUT | /api/v1/profile | 无 @PreAuthorize（同上） | ProfileUpdateDTO | Result\<Void\> | 修改个人信息 |
| PUT | /api/v1/profile/password | 无 @PreAuthorize（同上） | PasswordUpdateDTO | Result\<Void\> | 修改密码 |

### 在线用户

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/online-users | system:online:list | — | Result<List\<OnlineUserVO\>> | 查询在线用户 |
| DELETE | /api/v1/online-users/{tokenId} | system:online:kickout | — | Result\<Void\> | 强制下线 |

---

## DTO / VO 契约

### ProfileUpdateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| nickname | String | @Size(max=64) | 昵称 |
| email | String | @Email, @Size(max=100) | 邮箱 |
| phone | String | @Size(max=20) | 手机号 |

**禁止字段**：`id`、`tenantId`、`username`、`password`、所有审计字段

### PasswordUpdateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| oldPassword | String | @NotBlank | 旧密码（脱敏：`***`） |
| newPassword | String | @NotBlank, @Size(min=8, max=64) | 新密码（脱敏：`***`） |

**禁止字段**：`tenantId`、所有审计字段

---

## 实体 / 服务契约

```
Entity  : SysLoginLog extends BaseEntity
          业务字段见 DB 表结构，审计字段由 BaseEntity 继承

Mapper  : SysLoginLogMapper extends BaseMapper<SysLoginLog>
          自定义分页查询 SQL 在 SysLoginLogMapper.xml

Service : LoginLogAppService — listLoginLogs(query)
          ProfileAppService  — getProfile(), updateProfile(dto), updatePassword(dto)
          OnlineUserAppService — listOnlineUsers(), kickout(tokenId)
                               维护 Caffeine 缓存（key=jti，TTL=access token 过期时间）
```

---

## 业务规则

- **BL-22-01**：AuthController 登录成功/失败时 → 复用 LogAsyncConfig 线程池异步写入 sys_login_log → 不阻塞登录响应
- **BL-22-02**：日志中 password 字段输出为 `***`，phone 中间四位替换为 `****`
- **BL-22-03**：修改密码时 → 先验证 oldPassword 与数据库 BCrypt 哈希匹配，不匹配 → 抛出 `BusinessException(ErrorCode.OLD_PASSWORD_INCORRECT)`
- **BL-22-04**：OnlineUserAppService 维护 Caffeine 缓存（key=jti，value=OnlineUserVO，TTL=access token 过期时间）；登录时注册，强制下线时移除；JWT 过滤器校验 token 时同步检查缓存是否已被踢出

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-22-profile.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-22-01 | 无 Token → 401（登录日志/在线用户接口） | P0 |
| TC-22-02 | 无权限 → 403（system:log:login:list / system:online:list） | P0 |
| TC-22-03 | GET /api/v1/login-logs 返回分页数据 | P0 |
| TC-22-04 | GET /api/v1/profile 返回当前用户信息 | P0 |
| TC-22-05 | PUT /api/v1/profile 修改成功，再查询验证 | P0 |
| TC-22-06 | PUT /api/v1/profile/password 旧密码错误 → 400 | P0 |
| TC-22-07 | GET /api/v1/online-users 返回列表 | P0 |
| TC-22-08 | DELETE /api/v1/online-users/{tokenId} 强制下线后 token 失效 | P0 |

---

## 验收条件

- **AC-01**：V026 含 7 列审计字段，无 `IF NOT EXISTS`
- **AC-02**：LoginLogController 有 `@PreAuthorize("hasAuthority('system:log:login:list')")`；OnlineUserController 方法各有对应权限注解
- **AC-03**：ProfileController GET/PUT 方法无 `@PreAuthorize`，SecurityConfig 对 `/api/v1/profile/**` 配置 `authenticated()`
- **AC-04**：登录日志异步写入（@Async + LogAsyncConfig 线程池），不阻塞登录响应
- **AC-05**：password 字段日志脱敏为 `***`，PasswordUpdateDTO 中不含 `tenantId`
- **AC-06**：编译通过，所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT，禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:...')` —— 无 ROLE_ 前缀
- Profile 接口：无 @PreAuthorize，依赖 SecurityConfig `authenticated()` 保护
- 禁止：`IF NOT EXISTS` · `tenantId` in DTO · `any` in TypeScript
- 日志脱敏：password → `***`，phone → 中间四位 `****`
