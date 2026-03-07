---
phase: 52
title: "消息中台 - 订阅管理 (Message Center - Subscription Management)"
targets:
  backend: true
  frontend: true
depends_on: [51]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V052__create_msg_subscription.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/MsgSubscription.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/MsgSubscriptionController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/MsgSubscriptionService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/MsgSubscriptionMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/MsgSubscriptionMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/MsgSubscriptionDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/MsgSubscriptionVO.java"
  - "ljwx-platform-web/src/views/message/subscription/index.vue"
  - "ljwx-platform-web/src/api/message/subscription.ts"
---
# Phase 52 — 消息中台 - 订阅管理

| 项目 | 值 |
|-----|---|
| Phase | 52 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-web (前端) |
| Feature | L0-D07-F02 |
| 前置依赖 | Phase 51 (消息中台 - 模板管理) |
| 测试契约 | `spec/tests/phase-52-msg-subscription.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §消息订阅表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

## 功能概述

实现消息订阅管理,支持:
1. 用户订阅消息类型
2. 订阅渠道配置
3. 订阅状态管理
4. 订阅偏好设置

## 数据库契约

### 表结构：msg_subscription

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| user_id | BIGINT | NOT NULL, INDEX | 用户 ID |
| template_id | BIGINT | NOT NULL, INDEX | 模板 ID |
| channel | VARCHAR(20) | NOT NULL | EMAIL / SMS / WECHAT / PUSH |
| status | VARCHAR(20) | NOT NULL, INDEX | ACTIVE / INACTIVE |
| preference | JSONB | | 订阅偏好（频率、时段等） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_user_id` (user_id)
- `idx_template_id` (template_id)
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)
- `uk_user_template_channel` (user_id, template_id, channel) UNIQUE

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V052__create_msg_subscription.sql` | 建表 + 索引 + 唯一约束 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/message/subscriptions | system:message:subscription:add |
| PUT | /api/v1/message/subscriptions/{id} | system:message:subscription:edit |
| DELETE | /api/v1/message/subscriptions/{id} | system:message:subscription:delete |
| GET | /api/v1/message/subscriptions/{id} | system:message:subscription:query |
| GET | /api/v1/message/subscriptions | system:message:subscription:list |
| PUT | /api/v1/message/subscriptions/{id}/status | system:message:subscription:edit |

## 业务规则

- BL-52-01: 用户订阅 → 检查模板是否存在 → 创建订阅记录
- BL-52-02: 同一用户+模板+渠道 → 唯一约束 → 禁止重复订阅
- BL-52-03: 订阅状态变更 → ACTIVE/INACTIVE → 影响消息发送
- BL-52-04: 订阅偏好 → JSONB 存储 → 支持频率、时段等配置

## 核心组件契约

### MsgSubscription 实体

```java
@Data
@TableName("msg_subscription")
public class MsgSubscription extends BaseEntity {
    private Long userId;
    private Long templateId;
    private String channel;      // EMAIL / SMS / WECHAT / PUSH
    private String status;       // ACTIVE / INACTIVE
    private String preference;   // JSONB
}
```

### MsgSubscriptionDTO

```java
@Data
public class MsgSubscriptionDTO {
    @NotNull(message = "用户ID不能为空")
    private Long userId;

    @NotNull(message = "模板ID不能为空")
    private Long templateId;

    @NotBlank(message = "渠道不能为空")
    private String channel;      // EMAIL / SMS / WECHAT / PUSH

    @NotBlank(message = "状态不能为空")
    private String status;       // ACTIVE / INACTIVE

    private String preference;   // JSONB
}
```

### MsgSubscriptionVO

```java
@Data
public class MsgSubscriptionVO {
    private Long id;
    private Long userId;
    private String userName;
    private Long templateId;
    private String templateName;
    private String channel;
    private String status;
    private String preference;
    private LocalDateTime createdTime;
}
```

### MsgSubscriptionController

```java
@RestController
@RequestMapping("/api/v1/message/subscriptions")
@RequiredArgsConstructor
public class MsgSubscriptionController {

    @PostMapping
    @PreAuthorize("@ss.hasPermission('system:message:subscription:add')")
    public R<Long> create(@Valid @RequestBody MsgSubscriptionDTO dto) {
        // 创建订阅
    }

    @PutMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:message:subscription:edit')")
    public R<Void> update(@PathVariable Long id, @Valid @RequestBody MsgSubscriptionDTO dto) {
        // 更新订阅
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:message:subscription:delete')")
    public R<Void> delete(@PathVariable Long id) {
        // 删除订阅
    }

    @GetMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:message:subscription:query')")
    public R<MsgSubscriptionVO> getById(@PathVariable Long id) {
        // 查询订阅详情
    }

    @GetMapping
    @PreAuthorize("@ss.hasPermission('system:message:subscription:list')")
    public R<PageResult<MsgSubscriptionVO>> list(MsgSubscriptionQueryDTO query) {
        // 分页查询订阅列表
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("@ss.hasPermission('system:message:subscription:edit')")
    public R<Void> updateStatus(@PathVariable Long id, @RequestParam String status) {
        // 更新订阅状态
    }
}
```

## 前端文件路径

| 文件 | 说明 |
|------|------|
| `ljwx-platform-web/src/views/message/subscription/index.vue` | 订阅管理页面 |
| `ljwx-platform-web/src/api/message/subscription.ts` | API 调用封装 |

## 验收条件

- AC-01: 用户可以订阅消息模板
- AC-02: 支持多渠道订阅配置
- AC-03: 订阅状态管理正常
- AC-04: 订阅偏好设置生效

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-52-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-52-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-52-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-52-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-52-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-52-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-52-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-52-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-52-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-52-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
