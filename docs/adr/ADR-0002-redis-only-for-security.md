# ADR-0002: Token 黑名单与在线用户状态采用 Redis Only

## Status
Accepted

## Context
强制下线/黑名单若在本地缓存会出现"换 Pod 复活"问题。

在多副本部署场景下,如果 Token 黑名单和在线用户状态存储在本地缓存:
- 用户在 Pod A 被强制下线,Token 加入黑名单
- 但请求路由到 Pod B 时,Pod B 的本地缓存中没有该黑名单记录
- 用户仍然可以正常访问系统,强制下线失效

这是严重的安全漏洞,必须保证强一致性。

## Decision
`tokenBlacklist:{jti}`、`online:{tokenId}` 等全部存 Redis,并与 token 过期时间对齐 TTL。

### 实现细节
- **Token 黑名单**: `tokenBlacklist:{jti}` → Redis SET,TTL = token 剩余有效期
- **在线用户**: `online:{tokenId}` → Redis HASH,TTL = token 有效期
- **登录锁定**: `loginLock:{username}` → Redis STRING,TTL = 锁定时长
- **限流计数**: `rateLimit:{key}` → Redis STRING,TTL = 窗口时长

### 不使用本地缓存的原因
- 强制下线必须立即生效,不能有任何延迟
- 在线用户状态必须实时准确,用于监控和管理
- 限流计数必须全局一致,防止超限

## Consequences

### 正面影响
- 强制下线立即生效,无"换 Pod 复活"问题
- 在线用户状态实时准确
- 限流计数全局一致

### 负面影响
- 认证模块必须依赖 Redis
- Redis 不可用时需要降级策略

### 降级策略
Redis 不可用时的处理方案:
1. **拒绝登录/拒绝刷新** (推荐): 保证安全优先,宁可服务不可用也不能出现安全漏洞
2. **允许已登录用户继续访问**: 风险较高,不推荐
3. **降级到本地缓存**: 风险极高,禁止使用

**推荐**: 采用方案 1,Redis 不可用时拒绝登录和刷新,已登录用户可继续访问直到 Token 过期。

## References
- Phase 22: 在线用户管理
- Phase 28: Token 黑名单
- spec/phase/phase-22.md
