---
phase: 28
title: "Security Hardening XSS Idempotency Token Blacklist"
targets:
  backend: true
  frontend: false
depends_on: [27]
bundle_with: []
scope:
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/XssFilter.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/XssHttpServletRequestWrapper.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/annotation/Idempotent.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/interceptor/IdempotentInterceptor.java"
  - "ljwx-platform-security/src/main/java/com/ljwx/platform/security/blacklist/TokenBlacklistService.java"
  - "ljwx-platform-security/src/main/java/com/ljwx/platform/security/blacklist/LoginLockoutService.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/config/WebMvcConfig.java"
  - "ljwx-platform-security/src/main/java/com/ljwx/platform/security/config/SecurityConfig.java"
---
# Phase 28: Security Hardening — XSS / Idempotency / Token Blacklist

## Overview

| 属性 | 值 |
|------|-----|
| Phase | 28 |
| 模块 | ljwx-platform-web（XSS / 幂等 / 密码校验）、ljwx-platform-security（黑名单 / 锁定） |
| Feature | XSS 过滤 / 接口幂等 / Token 黑名单 / 登录锁定 / 强密码校验 |
| 前置依赖 | Phase 27 |
| 测试契约 | [spec/tests/phase-28-security.tests.yml](../tests/phase-28-security.tests.yml) |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §DAG 依赖、§安全
- `spec/04-database.md` — 无新表
- `spec/08-output-rules.md`

## 组件契约

| 组件 | 所在模块 | 核心行为 |
|------|---------|---------|
| XssHttpServletRequestWrapper | ljwx-platform-web | 继承 HttpServletRequestWrapper，重写 getParameter/getParameterValues/getHeader/getReader，对字符串值调用 HtmlUtils.htmlEscape() |
| XssFilter | ljwx-platform-web | jakarta.servlet.Filter，order=1，拦截 /api/**，排除 /api/v1/files/upload |
| @Idempotent + IdempotentInterceptor | ljwx-platform-web | 注解属性 expireSeconds（默认 10）；幂等键 = MD5(userId+URI+body 前 512B)，Caffeine 缓存 TTL=expireSeconds |
| TokenBlacklistService | ljwx-platform-security | void addToBlacklist(jti, remainingSeconds) / boolean isBlacklisted(jti)，Caffeine 缓存 TTL=token 剩余有效期 |
| LoginLockoutService | ljwx-platform-security | void recordFailure(username) / boolean isLocked(username) / void clearFailure(username)，失败 5 次锁定 30 分钟 |
| @StrongPassword + StrongPasswordValidator | ljwx-platform-web | ConstraintValidator，最少 8 位，满足大写+小写+数字+特殊字符至少 3 类 |

## 业务规则

| 规则 | 条件 → 结果 |
|------|-------------|
| BL-28-01 | 请求参数含 XSS 字符串（如 `<script>`）→ HtmlUtils.htmlEscape() 转义后放行；/api/v1/files/upload 路径跳过过滤 |
| BL-28-02 | @Idempotent 方法收到重复请求（幂等键命中 Caffeine 缓存）→ 返回 `Result.fail(ErrorCode.REPEAT_SUBMIT)` |
| BL-28-03 | 登出时 → jti 加入 TokenBlacklistService（Caffeine TTL=token 剩余有效期）；后续请求携带该 token → JwtAuthenticationFilter 返回 401 |
| BL-28-04 | 同一 username 登录失败累计 5 次 → LoginLockoutService 锁定 30 分钟；锁定期间登录请求返回 `ErrorCode.ACCOUNT_LOCKED` |
| BL-28-05 | password 字段标注 @StrongPassword → 不满足 3 类字符要求时 Bean Validation 返回 400 |

## P0 测试摘要

| TC ID | 场景 | 预期 |
|-------|------|------|
| TC-28-01 | 请求参数含 `<script>alert(1)</script>` | XssFilter 转义，接口正常返回 200，param 值已转义 |
| TC-28-02 | @Idempotent 端点 10 秒内重复提交 | 第 2 次返回 400，code=REPEAT_SUBMIT |
| TC-28-03 | POST /api/auth/logout → 再用原 token 请求 | 401，token 已失效 |
| TC-28-04 | 同账号连续 5 次密码错误 | 第 6 次返回 400，code=ACCOUNT_LOCKED |
| TC-28-05 | POST /api/v1/users，password="abc" | 400，@StrongPassword 校验失败 |
| TC-28-06 | POST /api/v1/users，password="UserCreate#6789" | 200，强密码校验通过 |

完整测试用例见 [spec/tests/phase-28-security.tests.yml](../tests/phase-28-security.tests.yml)。

## 关键约束

- XssFilter 位于 web 模块，禁止 import security 或 data 模块（DAG 合规）
- TokenBlacklistService / LoginLockoutService 位于 security 模块，使用已有 Caffeine 依赖，禁止 import data 模块
- IdempotentInterceptor 位于 web 模块，Caffeine 缓存复用已有配置，不新建 CacheManager
- 无新增数据库迁移

## 验收条件

1. XssFilter 对 `<script>alert(1)</script>` 参数返回转义后的字符串
2. IdempotentInterceptor 10 秒内重复请求返回 `REPEAT_SUBMIT` 错误码
3. TokenBlacklistService 登出后 token 失效（JwtAuthenticationFilter 返回 401）
4. LoginLockoutService 连续 5 次失败后账户锁定
5. @StrongPassword 对弱密码返回 400 校验错误
6. 编译通过，无 data 模块 import 在 security/web 中

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-28-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-28-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-28-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-28-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-28-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-28-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-28-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-28-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-28-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-28-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
