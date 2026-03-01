---
phase: 49
title: "Webhook 事件推送 (Webhook Event Push)"
targets:
  backend: true
  frontend: true
depends_on: [48]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V049__create_webhook.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/WebhookConfig.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/WebhookLog.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/WebhookController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/WebhookService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/WebhookConfigMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/WebhookLogMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/WebhookConfigMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/WebhookLogMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/WebhookConfigDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/WebhookConfigVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/WebhookLogVO.java"
  - "ljwx-platform-admin/src/views/system/webhook/index.vue"
  - "ljwx-platform-admin/src/api/system/webhook.ts"
---
# Phase 49 — Webhook 事件推送

| 项目 | 值 |
|-----|---|
| Phase | 49 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L0-D07-F03 |
| 前置依赖 | Phase 48 (开放 API 管理) |
| 测试契约 | `spec/tests/phase-49-webhook.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §Webhook 配置表、§Webhook 日志表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

## 功能概述

实现 Webhook 事件推送,支持:
1. Webhook 配置管理
2. 事件订阅机制
3. 推送重试策略
4. 推送日志记录

## 数据库契约

### 表结构：sys_webhook_config

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| webhook_name | VARCHAR(100) | NOT NULL | Webhook 名称 |
| webhook_url | VARCHAR(500) | NOT NULL | 推送 URL |
| event_types | TEXT | NOT NULL | 订阅事件类型（JSON 数组） |
| secret_key | VARCHAR(128) | NOT NULL | 签名密钥 |
| status | VARCHAR(20) | NOT NULL, INDEX | ENABLED / DISABLED |
| retry_count | INT | NOT NULL, DEFAULT 5 | 最大重试次数 |
| timeout_seconds | INT | NOT NULL, DEFAULT 5 | 超时时间（秒） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)

### 表结构：sys_webhook_log

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| webhook_id | BIGINT | NOT NULL, INDEX | FK → sys_webhook_config.id |
| event_type | VARCHAR(50) | NOT NULL | 事件类型 |
| event_data | TEXT | NOT NULL | 事件数据（JSON） |
| request_url | VARCHAR(500) | NOT NULL | 请求 URL |
| request_headers | TEXT | | 请求头（JSON） |
| request_body | TEXT | NOT NULL | 请求体 |
| response_status | INT | | HTTP 响应状态码 |
| response_body | TEXT | | 响应体 |
| retry_times | INT | NOT NULL, DEFAULT 0 | 已重试次数 |
| status | VARCHAR(20) | NOT NULL, INDEX | SUCCESS / FAILURE |
| error_message | TEXT | | 错误信息 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_webhook_id` (webhook_id)
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)
- `idx_created_time` (created_time)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V049__create_webhook.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/webhooks | system:webhook:add |
| PUT | /api/v1/webhooks/{id} | system:webhook:edit |
| DELETE | /api/v1/webhooks/{id} | system:webhook:delete |
| GET | /api/v1/webhooks/{id} | system:webhook:query |
| GET | /api/v1/webhooks | system:webhook:list |
| GET | /api/v1/webhooks/{id}/logs | system:webhook:log:list |

## 业务规则

> 格式：BL-49-{序号}：[条件] → [动作] → [结果/异常]

- **BL-49-01**：事件触发 → 异步推送到订阅的 Webhook → 记录推送日志
- **BL-49-02**：推送失败 → 指数退避重试 (1s, 2s, 4s, 8s, 16s) → 达到最大次数标记 FAILURE
- **BL-49-03**：签名验证 → HMAC-SHA256(key=secret_key, data=timestamp+"\n"+body_hash) → 防止伪造请求
- **BL-49-04**：超时控制 → 默认 5 秒 → 超时视为失败并重试
- **BL-49-05**：Webhook 配置 DISABLED → 跳过推送 → 不记录日志

## 核心组件契约

### WebhookConfig 实体

```java
@Data
@TableName("sys_webhook_config")
public class WebhookConfig extends BaseEntity {
    private String webhookName;
    private String webhookUrl;
    private String eventTypes;      // JSON 数组
    private String secretKey;
    private String status;          // ENABLED / DISABLED
    private Integer retryCount;
    private Integer timeoutSeconds;
}
```

### WebhookLog 实体

```java
@Data
@TableName("sys_webhook_log")
public class WebhookLog extends BaseEntity {
    private Long webhookId;
    private String eventType;
    private String eventData;       // JSON
    private String requestUrl;
    private String requestHeaders;  // JSON
    private String requestBody;
    private Integer responseStatus;
    private String responseBody;
    private Integer retryTimes;
    private String status;          // SUCCESS / FAILURE
    private String errorMessage;
}
```

### WebhookConfigDTO

```java
@Data
public class WebhookConfigDTO {
    @NotBlank(message = "Webhook 名称不能为空")
    private String webhookName;

    @NotBlank(message = "Webhook URL 不能为空")
    @Pattern(regexp = "^https?://.*", message = "URL 格式不正确")
    private String webhookUrl;

    @NotNull(message = "事件类型不能为空")
    private List<String> eventTypes;

    @NotBlank(message = "签名密钥不能为空")
    private String secretKey;

    @NotBlank(message = "状态不能为空")
    private String status;          // ENABLED / DISABLED

    private Integer retryCount;     // 默认 5
    private Integer timeoutSeconds; // 默认 5
}
```

### WebhookConfigVO

```java
@Data
public class WebhookConfigVO {
    private Long id;
    private String webhookName;
    private String webhookUrl;
    private List<String> eventTypes;
    private String status;
    private Integer retryCount;
    private Integer timeoutSeconds;
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
}
```

### WebhookLogVO

```java
@Data
public class WebhookLogVO {
    private Long id;
    private Long webhookId;
    private String webhookName;
    private String eventType;
    private String eventData;
    private String requestUrl;
    private Integer responseStatus;
    private String responseBody;
    private Integer retryTimes;
    private String status;
    private String errorMessage;
    private LocalDateTime createdTime;
}
```

### WebhookController

```java
@RestController
@RequestMapping("/api/v1/webhooks")
@RequiredArgsConstructor
public class WebhookController {

    @PostMapping
    @PreAuthorize("@ss.hasPermission('system:webhook:add')")
    public R<Long> create(@Valid @RequestBody WebhookConfigDTO dto) {
        // 创建 Webhook 配置
    }

    @PutMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:webhook:edit')")
    public R<Void> update(@PathVariable Long id, @Valid @RequestBody WebhookConfigDTO dto) {
        // 更新 Webhook 配置
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:webhook:delete')")
    public R<Void> delete(@PathVariable Long id) {
        // 删除 Webhook 配置
    }

    @GetMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:webhook:query')")
    public R<WebhookConfigVO> getById(@PathVariable Long id) {
        // 查询 Webhook 配置详情
    }

    @GetMapping
    @PreAuthorize("@ss.hasPermission('system:webhook:list')")
    public R<PageResult<WebhookConfigVO>> list(WebhookConfigQueryDTO query) {
        // 分页查询 Webhook 配置列表
    }

    @GetMapping("/{id}/logs")
    @PreAuthorize("@ss.hasPermission('system:webhook:log:list')")
    public R<PageResult<WebhookLogVO>> listLogs(@PathVariable Long id, WebhookLogQueryDTO query) {
        // 查询 Webhook 推送日志
    }
}
```

### WebhookSignatureUtil

```java
public class WebhookSignatureUtil {

    /**
     * 生成 Webhook HMAC-SHA256 签名
     * @param secretKey 密钥
     * @param timestamp 时间戳
     * @param bodyHash 请求体 SHA-256 哈希
     * @return Base64 编码的签名
     */
    public static String generateSignature(String secretKey, String timestamp, String bodyHash) {
        try {
            // 1. 构造待签名数据 (使用换行符分隔)
            String data = timestamp + "\n" + bodyHash;

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
     * 验证 Webhook HMAC-SHA256 签名
     * @param signature 待验证的签名
     * @param secretKey 密钥
     * @param timestamp 时间戳
     * @param bodyHash 请求体 SHA-256 哈希
     * @return 签名是否有效
     */
    public static boolean verifySignature(String signature, String secretKey, String timestamp, String bodyHash) {
        String expectedSignature = generateSignature(secretKey, timestamp, bodyHash);
        return MessageDigest.isEqual(
            signature.getBytes(StandardCharsets.UTF_8),
            expectedSignature.getBytes(StandardCharsets.UTF_8)
        );
    }
}
```

## 前端文件路径

| 文件 | 说明 |
|------|------|
| `ljwx-platform-admin/src/views/system/webhook/index.vue` | Webhook 配置管理页面 |
| `ljwx-platform-admin/src/api/system/webhook.ts` | API 调用封装 |

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：Webhook 配置正常创建和管理
- **AC-03**：事件推送成功并记录日志
- **AC-04**：重试机制生效,指数退避策略正确
- **AC-05**：推送日志完整,包含请求和响应详情
- **AC-06**：签名验证机制正常工作
- **AC-07**：编译通过,所有 P0 用例通过
