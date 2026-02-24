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

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §DAG 依赖、§安全
- `spec/04-database.md` — 无新表
- `spec/08-output-rules.md`

## 任务

### 1. XSS 过滤器（web 模块）

**XssHttpServletRequestWrapper**：继承 `HttpServletRequestWrapper`，重写 `getParameter`/`getParameterValues`/`getHeader`/`getReader`，对所有字符串值调用 `HtmlUtils.htmlEscape()`（Spring 内置，无需额外依赖）。

**XssFilter**：实现 `jakarta.servlet.Filter`，对所有 `/api/**` 路径生效，排除 `/api/v1/files/upload`（文件上传不过滤）。注册为 `@Bean`，order=1（最高优先级）。

### 2. 接口幂等注解（web 模块）

**@Idempotent 注解**：
```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Idempotent {
    int expireSeconds() default 10; // 幂等窗口，默认 10 秒
}
```

**IdempotentInterceptor**：
- 仅拦截标注 `@Idempotent` 的方法
- 幂等键 = MD5(userId + requestURI + requestBody 前 512 字节)
- 用 Caffeine 缓存（key=幂等键，value=true，TTL=expireSeconds）
- 重复请求返回 `Result.fail(ErrorCode.REPEAT_SUBMIT)`
- 注入 `WebMvcConfig` 的 `addInterceptors`

### 3. Token 黑名单（security 模块）

**TokenBlacklistService**：
```java
@Service
public class TokenBlacklistService {
    // 使用 Caffeine 缓存，key=jti，TTL=token 剩余有效期
    void addToBlacklist(String jti, long remainingSeconds);
    boolean isBlacklisted(String jti);
}
```

修改 `JwtAuthenticationFilter`：校验 token 后检查 jti 是否在黑名单中，若在则返回 401。

修改登出接口（AuthController 的 `/api/v1/auth/logout`）：将当前 token 的 jti 加入黑名单。

### 4. 登录失败锁定（security 模块）

**LoginLockoutService**：
```java
@Service
public class LoginLockoutService {
    // Caffeine 缓存：key=username，value=失败次数
    // 失败 5 次后锁定 30 分钟
    void recordFailure(String username);
    boolean isLocked(String username);
    void clearFailure(String username); // 登录成功后清除
}
```

修改 `UserDetailsServiceImpl`（或 AuthAppService 的登录方法）：
- 登录前检查 `isLocked(username)`，若锁定返回 `ErrorCode.ACCOUNT_LOCKED`
- 登录失败调用 `recordFailure(username)`
- 登录成功调用 `clearFailure(username)`

### 5. 密码复杂度校验

在 `PasswordUpdateDTO` 和用户创建 DTO 的 password 字段增加自定义注解 `@StrongPassword`：
- 最少 8 位
- 必须包含大写字母、小写字母、数字、特殊字符（`!@#$%^&*`）中至少 3 类

`@StrongPassword` 注解 + `StrongPasswordValidator` 实现 `ConstraintValidator`，放在 `ljwx-platform-web` 模块。

## 关键约束

- XssFilter 在 web 模块，不依赖 security/data（DAG 合规）
- TokenBlacklistService 在 security 模块，使用 Caffeine（已有依赖，无需新增）
- LoginLockoutService 在 security 模块
- 无新增数据库迁移
- Caffeine 缓存 Bean 复用已有配置，不新建 CacheManager

## Phase-Local Manifest

```
ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/XssFilter.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/XssHttpServletRequestWrapper.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/annotation/Idempotent.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/interceptor/IdempotentInterceptor.java
ljwx-platform-security/src/main/java/com/ljwx/platform/security/blacklist/TokenBlacklistService.java
ljwx-platform-security/src/main/java/com/ljwx/platform/security/blacklist/LoginLockoutService.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/config/WebMvcConfig.java
ljwx-platform-security/src/main/java/com/ljwx/platform/security/config/SecurityConfig.java
```

## 验收条件

1. XssFilter 对 `<script>alert(1)</script>` 参数返回转义后的字符串
2. IdempotentInterceptor 10 秒内重复请求返回 `REPEAT_SUBMIT` 错误码
3. TokenBlacklistService 登出后 token 失效（JwtAuthenticationFilter 返回 401）
4. LoginLockoutService 连续 5 次失败后账户锁定
5. @StrongPassword 对弱密码返回 400 校验错误
6. 编译通过，无 data 模块 import 在 security/web 中
