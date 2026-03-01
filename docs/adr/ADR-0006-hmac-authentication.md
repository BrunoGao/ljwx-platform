# ADR-0006: 开放平台认证采用 HMAC + timestamp + nonce 防重放 + 密钥轮换

## Status
Accepted

## Context
开放 API 面向系统对系统调用,JWT 不适用；基础 HMAC 若无 nonce/时间校验容易被重放攻击；密钥需要可轮换。

### 问题场景
1. **JWT 不适用**: 开放 API 是系统对系统调用,不需要用户身份,JWT 过重
2. **重放攻击**: 攻击者截获请求后重放,导致重复操作
3. **密钥泄露**: 密钥泄露后无法快速轮换,影响所有调用方
4. **时间窗口**: 请求可能因网络延迟到达,需要容忍一定时间差

### 常见方案对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| API Key | 简单 | 无防重放,密钥泄露风险高 |
| HMAC | 防篡改 | 无防重放,无时间校验 |
| OAuth 2.0 | 标准化 | 过重,需要授权服务器 |
| HMAC + timestamp + nonce | 防篡改 + 防重放 | 需要 Redis,实现复杂 |

## Decision
HMAC 签名覆盖：method + path + timestamp + nonce + body_hash

### 签名算法
```
signature = HMAC-SHA256(secret,
    method + "\n" +
    path + "\n" +
    timestamp + "\n" +
    nonce + "\n" +
    SHA256(body)
)
```

### 请求头
```
X-App-Key: {appKey}
X-Timestamp: {timestamp}  // Unix 时间戳 (秒)
X-Nonce: {nonce}          // 随机字符串 (UUID)
X-Signature: {signature}  // HMAC-SHA256 签名
```

### 验签流程
1. **时间窗口校验**: `|now - timestamp| <= 5min`
2. **nonce 去重**: Redis `SETNX(appKey:nonce, 1, TTL=10min)`
3. **签名验证**: 重新计算签名并比对
4. **密钥轮换**: 先用 primary_secret 验签,失败则用 secondary_secret

### 密钥轮换流程
1. **生成 secondary**: 管理员生成新密钥,保存到 `secondary_secret`
2. **灰度验证**: 调用方使用新密钥测试,验签时 primary 和 secondary 都尝试
3. **切换生效**: 管理员执行 "promote",secondary → primary
4. **清理旧密钥**: 旧 primary 失效,调用方必须使用新密钥

## Consequences

### 正面影响
- 防篡改: HMAC 签名保证请求完整性
- 防重放: timestamp + nonce 防止重放攻击
- 密钥轮换: 支持无缝轮换,降低泄露风险

### 负面影响
- 必须依赖 Redis (nonce 去重)
- 需要管理界面支持轮换与停用
- 需要安全审计与告警

### 实施要点

#### 1. 时间窗口
- 允许 ±5min 时间差,容忍网络延迟和时钟偏移
- 超过时间窗口的请求直接拒绝 (401 Unauthorized)

#### 2. nonce 去重
- Redis Key: `open:nonce:{appKey}:{nonce}`
- TTL: 10min (时间窗口的 2 倍)
- 重复 nonce 返回 409 Conflict

#### 3. 密钥轮换
- primary_secret: 当前生效的密钥
- secondary_secret: 灰度期的新密钥 (可空)
- 验签时先用 primary,失败则用 secondary
- promote 后,secondary → primary,旧 primary 失效

#### 4. 安全审计
- 记录所有验签失败的请求 (appKey, IP, 失败原因)
- 异常频率告警 (如 1 分钟内 10 次验签失败)

## References
- Phase 29: 开放平台 HMAC 鉴权
- spec/phase/phase-29.md (待生成)
