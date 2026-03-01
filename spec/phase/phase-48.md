---
phase: 48
title: "开放 API 管理 - 密钥管理 (Open API - Secret Management)"
targets:
  backend: true
  frontend: true
depends_on: [47]
bundle_with: [47]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V048__create_open_app_secret.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/OpenAppSecret.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/OpenAppSecretController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/OpenAppSecretService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/OpenAppSecretMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/OpenAppSecretMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/OpenAppSecretDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/OpenAppSecretVO.java"
  - "ljwx-platform-web/src/views/system/open-api/secret/index.vue"
  - "ljwx-platform-web/src/api/system/open-api-secret.ts"
---
# Phase 48 — 开放 API 管理 - 密钥管理

| 项目 | 值 |
|-----|---|
| Phase | 48 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-web (前端) |
| Feature | L0-D07-F02 |
| 前置依赖 | Phase 47 (开放 API 管理 - 应用管理) |
| 测试契约 | `spec/tests/phase-48-open-api-secret.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

> 仅读取以下文件(禁止扫描整个 spec/)

- `CLAUDE.md`(自动加载)
- `spec/04-database.md` — §开放 API 密钥表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

---

## 功能概述

实现开放 API 密钥管理,支持:
1. 密钥生成 (256-bit 随机密钥)
2. 密钥轮换 (旧密钥自动过期)
3. HMAC 签名验证 (HMAC-SHA256)
4. nonce 防重放 (Redis 10 分钟窗口)

---

## 数据库契约

### 表结构: open_app_secret

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键(雪花 ID) |
| app_id | BIGINT | NOT NULL, INDEX, FK → open_app.id | 应用 ID |
| secret_key | VARCHAR(128) | NOT NULL | 加密存储的密钥 |
| secret_version | INT | NOT NULL, DEFAULT 1 | 密钥版本号 |
| status | VARCHAR(20) | NOT NULL, INDEX | ACTIVE / EXPIRED |
| expire_time | TIMESTAMP | | 过期时间 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_app_id` (app_id)
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)

> 审计字段(最后 7 列)由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V048__create_open_app_secret.sql` | 建表 + 索引 + 外键约束 |

禁止: `IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/open-api/apps/{appId}/secrets | system:openApi:secret:add |
| PUT | /api/v1/open-api/apps/{appId}/secrets/{id}/rotate | system:openApi:secret:edit |
| DELETE | /api/v1/open-api/apps/{appId}/secrets/{id} | system:openApi:secret:delete |
| GET | /api/v1/open-api/apps/{appId}/secrets | system:openApi:secret:list |

---

## 业务规则

> 格式: BL-48-{序号}: [条件] → [动作] → [结果/异常]

- **BL-48-01**: 密钥生成 → 使用 SecureRandom 生成 256-bit 随机密钥 → Base64 编码存储
- **BL-48-02**: 密钥轮换 → 旧密钥标记 EXPIRED → 生成新密钥(版本号+1)
- **BL-48-03**: HMAC 签名 → HMAC-SHA256(key=secret_key, data=app_key+"\n"+timestamp+"\n"+nonce+"\n"+body_hash) → 验证签名
- **BL-48-04**: nonce 防重放 → Redis 存储 nonce(TTL=10分钟) → 重复 nonce 拒绝请求
- **BL-48-05**: 密钥过期 → expire_time < NOW() → 自动标记 EXPIRED
- **BL-48-06**: 每个应用 → 最多保留 3 个 ACTIVE 密钥 → 超过限制拒绝生成
- **BL-48-07**: 密钥删除 → 软删除(deleted=true) → 保留审计记录

---

## 核心组件契约

### OpenAppSecret 实体

```java
@Data
@TableName("open_app_secret")
public class OpenAppSecret extends BaseEntity {
    private Long appId;
    private String secretKey;      // 加密存储
    private Integer secretVersion;
    private String status;         // ACTIVE / EXPIRED
    private LocalDateTime expireTime;
}
```

### OpenAppSecretDTO

```java
@Data
public class OpenAppSecretDTO {
    @NotNull(message = "应用 ID 不能为空")
    private Long appId;

    private Integer validDays;     // 有效天数(默认 365)
}
```

### OpenAppSecretVO

```java
@Data
public class OpenAppSecretVO {
    private Long id;
    private Long appId;
    private String secretKey;      // 仅创建时返回明文,其他时候脱敏
    private Integer secretVersion;
    private String status;
    private LocalDateTime expireTime;
    private LocalDateTime createdTime;
}
```

### OpenAppSecretController

```java
@RestController
@RequestMapping("/api/v1/open-api/apps/{appId}/secrets")
@RequiredArgsConstructor
public class OpenAppSecretController {

    @PostMapping
    @PreAuthorize("@ss.hasPermission('system:openApi:secret:add')")
    public R<OpenAppSecretVO> createSecret(@PathVariable Long appId, @Valid @RequestBody OpenAppSecretDTO dto) {
        // 生成新密钥
    }

    @PutMapping("/{id}/rotate")
    @PreAuthorize("@ss.hasPermission('system:openApi:secret:edit')")
    public R<OpenAppSecretVO> rotateSecret(@PathVariable Long appId, @PathVariable Long id) {
        // 轮换密钥
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:openApi:secret:delete')")
    public R<Void> deleteSecret(@PathVariable Long appId, @PathVariable Long id) {
        // 删除密钥
    }

    @GetMapping
    @PreAuthorize("@ss.hasPermission('system:openApi:secret:list')")
    public R<List<OpenAppSecretVO>> listSecrets(@PathVariable Long appId) {
        // 查询密钥列表
    }
}
```

### HmacSignatureUtil

```java
public class HmacSignatureUtil {

    /**
     * 生成 HMAC-SHA256 签名
     * @param secretKey 密钥
     * @param appKey 应用标识
     * @param timestamp 时间戳
     * @param nonce 随机数
     * @param bodyHash 请求体 SHA-256 哈希
     * @return Base64 编码的签名
     */
    public static String generateSignature(String secretKey, String appKey, String timestamp, String nonce, String bodyHash) {
        try {
            // 1. 构造待签名数据 (使用换行符分隔)
            String data = appKey + "\n" + timestamp + "\n" + nonce + "\n" + bodyHash;

            // 2. 使用 HMAC-SHA256 算法
            Mac hmac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            hmac.init(secretKeySpec);

            // 3. 计算签名
            byte[] signatureBytes = hmac.doFinal(data.getBytes(StandardCharsets.UTF_8));

            // 4. Base64 编码
            return Base64.getEncoder().encodeToString(signatureBytes);
        } catch (Exception e) {
            throw new RuntimeException("HMAC signature generation failed", e);
        }
    }

    /**
     * 验证 HMAC-SHA256 签名
     * @param signature 待验证的签名
     * @param secretKey 密钥
     * @param appKey 应用标识
     * @param timestamp 时间戳
     * @param nonce 随机数
     * @param bodyHash 请求体 SHA-256 哈希
     * @return 签名是否有效
     */
    public static boolean verifySignature(String signature, String secretKey, String appKey, String timestamp, String nonce, String bodyHash) {
        String expectedSignature = generateSignature(secretKey, appKey, timestamp, nonce, bodyHash);
        return MessageDigest.isEqual(
            signature.getBytes(StandardCharsets.UTF_8),
            expectedSignature.getBytes(StandardCharsets.UTF_8)
        );
    }
}
```

---

## 前端文件路径

| 文件 | 说明 |
|------|------|
| `ljwx-platform-web/src/views/system/open-api/secret/index.vue` | 密钥管理页面 |
| `ljwx-platform-web/src/api/system/open-api-secret.ts` | API 调用封装 |

---

## 验收条件

- **AC-01**: Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**: 密钥生成使用 SecureRandom,256-bit 强度
- **AC-03**: 密钥轮换正常,旧密钥自动标记 EXPIRED
- **AC-04**: HMAC-SHA256 签名验证通过
- **AC-05**: nonce 防重放生效,Redis TTL=10 分钟
- **AC-06**: 密钥过期自动标记 EXPIRED
- **AC-07**: 每个应用最多 3 个 ACTIVE 密钥
- **AC-08**: 密钥删除为软删除,保留审计记录
- **AC-09**: 编译通过,所有 P0 用例通过

---

## 关键约束(硬规则速查)

- 审计字段: 7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 密钥生成: 使用 SecureRandom,256-bit 强度
- 密钥存储: 加密存储,仅创建时返回明文
- 密钥轮换: 旧密钥标记 EXPIRED,版本号递增
- nonce 防重放: Redis 存储,TTL=10 分钟
- 禁止: 在 DTO 中声明 `tenantId`

