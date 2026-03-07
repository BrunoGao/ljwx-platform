---
phase: 3
title: "Security Module"
targets:
  backend: true
  frontend: false
depends_on: [1]
bundle_with: [2]
scope:
  - "ljwx-platform-security/**"
---
# Phase 3 — 安全模块 (Security Module)

| 项目 | 值 |
|-----|---|
| Phase | 3 |
| 模块 | ljwx-platform-security |
| Feature | F-003 (JWT 认证授权) |
| 前置依赖 | Phase 1 (Core Module) |
| 测试契约 | `spec/tests/phase-03-security.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §JWT 认证
- `spec/02-architecture.md` — §模块依赖图、§DAG 约束
- `spec/08-output-rules.md`

---

## 类契约

### JwtTokenProvider（JWT 工具类）

| 方法 | 说明 |
|------|------|
| generateAccessToken(userId, tenantId, authorities) | 生成 access token（30分钟） |
| generateRefreshToken(userId, tenantId) | 生成 refresh token（7天） |
| validateToken(token) | 验证 token 有效性 |
| getUserIdFromToken(token) | 从 token 提取 userId |
| getTenantIdFromToken(token) | 从 token 提取 tenantId |
| getAuthoritiesFromToken(token) | 从 token 提取权限列表 |

JWT Claims：
- `sub`: userId
- `tenantId`: tenantId
- `authorities`: 权限字符串列表（无 ROLE_ 前缀）
- `type`: "access" 或 "refresh"

### SecurityContextUserHolder（实现类）

实现 `CurrentUserHolder` 接口，从 SecurityContext 获取当前用户 ID。

### SecurityContextTenantHolder（实现类）

实现 `CurrentTenantHolder` 接口，从 SecurityContext 获取当前租户 ID。

### JwtAuthenticationFilter（过滤器）

从请求头 `Authorization: Bearer {token}` 提取 JWT，验证后设置 SecurityContext。

### SecurityConfig（配置类）

| 配置项 | 说明 |
|--------|------|
| permitAll | /api/auth/login, /api/auth/refresh, /actuator/health |
| authenticated | 其他所有 /api/** 路径 |
| CORS | 允许跨域 |

---

## 业务规则

- **BL-03-01**：security 模块**仅依赖 core**，禁止依赖 data
- **BL-03-02**：JWT authorities claim 不添加 ROLE_ 前缀，直接使用权限字符串（如 system:user:list）
- **BL-03-03**：access token 有效期 30 分钟，refresh token 有效期 7 天
- **BL-03-04**：SecurityContextUserHolder 和 SecurityContextTenantHolder 实现 core 接口，供 data 模块使用

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-03-security.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-03-01 | pom.xml 仅依赖 core，无 data | P0 |
| TC-03-02 | 全部 import 无 com.ljwx.platform.data | P0 |
| TC-03-03 | SecurityContextUserHolder 实现 CurrentUserHolder | P0 |
| TC-03-04 | SecurityContextTenantHolder 实现 CurrentTenantHolder | P0 |
| TC-03-05 | JwtTokenProvider 使用 HS256 | P0 |
| TC-03-06 | SecurityConfig 允许 /api/auth/login 匿名访问 | P0 |
| TC-03-07 | 编译通过 | P0 |

---

## 验收条件

- **AC-01**：`pom.xml` 依赖仅含 `ljwx-platform-core`，无 `ljwx-platform-data`
- **AC-02**：全部 import 无 `com.ljwx.platform.data`
- **AC-03**：SecurityContextUserHolder 实现 CurrentUserHolder
- **AC-04**：SecurityContextTenantHolder 实现 CurrentTenantHolder
- **AC-05**：JwtTokenProvider 使用 HS256，支持 access/refresh 两种 type
- **AC-06**：SecurityConfig 中 `/api/auth/login` 和 `/api/auth/refresh` 允许匿名
- **AC-07**：`./mvnw compile -pl ljwx-platform-security` 通过

---

## 关键约束

- 禁止：依赖 data 模块 · JWT authorities 添加 ROLE_ 前缀
- DAG 约束：security 和 data 互不依赖，均只依赖 core
- JWT 算法：HS256（对称加密）

## 可 Bundle

可与 Phase 2 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-03-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-03-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-03-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-03-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-03-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-03-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-03-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-03-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-03-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-03-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
