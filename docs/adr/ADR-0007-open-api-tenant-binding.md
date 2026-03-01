# ADR-0007: 开放 API 的 tenantId 以 open_app 绑定为准，忽略客户端声明

## Status
Accepted

## Context
若信任 `X-Tenant-Id` 会被伪造越权跨租户。

在开放 API 场景下,如果信任客户端传递的 `X-Tenant-Id` 或 `tenantId` 参数:
- 攻击者可以伪造 tenantId,访问其他租户的数据
- 即使有 HMAC 签名,也无法防止合法调用方越权访问

### 问题示例
```http
POST /open/v1/users
X-App-Key: app123
X-Tenant-Id: tenant999  // 伪造其他租户 ID
X-Signature: ...
```

如果系统信任 `X-Tenant-Id`,攻击者可以:
1. 使用自己的 appKey 和 secret 生成合法签名
2. 伪造 tenantId,访问其他租户的数据
3. 绕过租户隔离,造成严重安全漏洞

## Decision
/open/v1 的租户上下文从 `sys_open_app.tenant_id` 注入,**忽略任何外部 tenant header/param**。

### 实现方案

#### 1. open_app 绑定租户
```sql
CREATE TABLE sys_open_app (
    id BIGINT PRIMARY KEY,
    app_key VARCHAR(64) NOT NULL UNIQUE,
    tenant_id BIGINT NOT NULL,  -- 绑定的租户 ID
    ...
);
```

#### 2. 认证后注入租户上下文
```java
@Component
public class OpenApiAuthFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request, ...) {
        // 1. 验证 HMAC 签名
        OpenApp openApp = verifySignature(request);

        // 2. 从 open_app 注入租户上下文
        TenantContext.setTenantId(openApp.getTenantId());

        // 3. 忽略客户端传递的 X-Tenant-Id
        // String clientTenantId = request.getHeader("X-Tenant-Id");
        // ❌ 不使用 clientTenantId

        chain.doFilter(request, response);
    }
}
```

#### 3. 多租户场景
如果一个 ISV 需要为多个租户调用开放 API:
- **方案 1**: 为每个租户创建独立的 open_app (推荐)
- **方案 2**: 使用超级 open_app,允许指定 tenantId (需要额外权限控制)

**推荐方案 1**,保持简单和安全。

## Consequences

### 正面影响
- 防止租户 ID 伪造,保证租户隔离
- 简化权限模型,租户上下文由系统控制

### 负面影响
- 开放平台必须在认证后才能解析 tenant
- 网关/过滤器顺序需保证先鉴权再注入 TenantContext
- 多租户 ISV 需要为每个租户创建独立的 open_app

### 实施要点

#### 1. 过滤器顺序
```java
@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain openApiFilterChain(HttpSecurity http) {
        http
            .addFilterBefore(openApiAuthFilter, UsernamePasswordAuthenticationFilter.class)
            .addFilterAfter(tenantContextFilter, OpenApiAuthFilter.class);
        return http.build();
    }
}
```

#### 2. 租户隔离验证
- 所有开放 API 的数据访问必须带 tenantId 条件
- 使用 MyBatis-Plus TenantLineHandler 自动注入
- 编写测试用例验证租户隔离

#### 3. 审计日志
- 记录 open_app 的 tenantId 和实际操作的数据
- 监控跨租户访问尝试 (理论上不应该发生)

## References
- Phase 29: 开放平台认证
- spec/phase/phase-29.md (待生成)
