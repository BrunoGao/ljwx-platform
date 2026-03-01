---
phase: 51
title: "消息中台 - 消息记录 (Message Center - Records)"
targets:
  backend: true
  frontend: true
depends_on: [50]
bundle_with: [50]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V051__create_msg_record_and_inbox.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/MsgRecord.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/MsgUserInbox.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/MessageController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/MessageService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/MsgRecordMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/MsgUserInboxMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/MsgRecordMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/MsgUserInboxMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/MessageSendDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/MsgRecordVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/MsgUserInboxVO.java"
  - "ljwx-platform-admin/src/views/system/message/records.vue"
  - "ljwx-platform-admin/src/views/system/message/inbox.vue"
  - "ljwx-platform-admin/src/api/system/message.ts"
---
# Phase 51 — 消息中台 - 消息记录

| 项目 | 值 |
|-----|---|
| Phase | 51 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L0-D07-F02 |
| 前置依赖 | Phase 50 (消息模板) |
| 测试契约 | `spec/tests/phase-51-message-records.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §消息记录表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 当前系统缺少统一的消息发送和记录机制,无法追踪消息发送状态和历史。

**解决方案**: 实现消息中台的消息记录功能,支持:
1. 站内信发送和管理
2. 邮件发送记录
3. 短信发送记录
4. 消息发送状态跟踪
5. 用户收件箱管理

---

## 数据库契约

### 表结构：msg_record

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| template_id | BIGINT | FK, INDEX | 消息模板 ID (msg_template.id) |
| message_type | VARCHAR(20) | NOT NULL, INDEX | INBOX / EMAIL / SMS |
| receiver_id | BIGINT | INDEX | 接收用户 ID |
| receiver_address | VARCHAR(200) | | 邮箱/手机号 |
| subject | VARCHAR(200) | NOT NULL | 消息主题 |
| content | TEXT | NOT NULL | 消息内容 |
| send_status | VARCHAR(20) | NOT NULL, INDEX | PENDING / SUCCESS / FAILURE |
| send_time | TIMESTAMP | | 发送成功时间 |
| error_message | TEXT | | 错误信息 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_template_id` (template_id)
- `idx_message_type` (message_type)
- `idx_receiver_id` (receiver_id)
- `idx_send_status` (send_status)
- `idx_tenant_id` (tenant_id)
- `idx_created_time` (created_time)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### 表结构：msg_user_inbox

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| user_id | BIGINT | NOT NULL, INDEX | 用户 ID (sys_user.id) |
| message_id | BIGINT | NOT NULL, INDEX | 消息记录 ID (msg_record.id) |
| title | VARCHAR(200) | NOT NULL | 消息标题 |
| content | TEXT | NOT NULL | 消息内容 |
| is_read | BOOLEAN | NOT NULL, DEFAULT FALSE, INDEX | 是否已读 |
| read_time | TIMESTAMP | | 阅读时间 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_user_id` (user_id)
- `idx_message_id` (message_id)
- `idx_is_read` (is_read)
- `idx_tenant_id` (tenant_id)
- `idx_created_time` (created_time)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V051__create_msg_record_and_inbox.sql` | 建表 + 索引 + 外键 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| POST | /api/v1/messages/send | system:message:send | 发送消息 |
| GET | /api/v1/messages/records | system:message:record:list | 查询消息记录列表 |
| GET | /api/v1/messages/records/{id} | system:message:record:query | 查询消息记录详情 |
| GET | /api/v1/messages/inbox | system:message:inbox:list | 查询用户收件箱 |
| PUT | /api/v1/messages/inbox/{id}/read | system:message:inbox:read | 标记消息已读 |
| DELETE | /api/v1/messages/inbox/{id} | system:message:inbox:delete | 删除收件箱消息 |

---

## 业务规则

> 格式：BL-51-{序号}：[条件] → [动作] → [结果/异常]

- **BL-51-01**：发送消息 → 创建 msg_record (status=PENDING) → 异步处理发送
- **BL-51-02**：站内信发送 → 写入 msg_user_inbox → 推送实时通知
- **BL-51-03**：邮件/短信发送 → 调用第三方服务 → 更新 send_status
- **BL-51-04**：发送失败 → 重试 3 次 → 仍失败则标记 FAILURE
- **BL-51-05**：用户查看收件箱 → 仅返回 user_id 匹配的消息 → 按创建时间倒序
- **BL-51-06**：标记已读 → 更新 is_read=true, read_time=NOW() → 返回成功
- **BL-51-07**：删除收件箱消息 → 软删除 (deleted=true) → 不影响 msg_record
- **BL-51-08**：消息发送成功 → 更新 send_status=SUCCESS, send_time=NOW() → 记录日志

---

## 核心组件契约

### MsgRecord 实体

```java
@Data
@TableName("msg_record")
public class MsgRecord extends BaseEntity {
    private Long templateId;
    private String messageType;    // INBOX / EMAIL / SMS
    private Long receiverId;
    private String receiverAddress;
    private String subject;
    private String content;
    private String sendStatus;     // PENDING / SUCCESS / FAILURE
    private LocalDateTime sendTime;
    private String errorMessage;
}
```

### MsgUserInbox 实体

```java
@Data
@TableName("msg_user_inbox")
public class MsgUserInbox extends BaseEntity {
    private Long userId;
    private Long messageId;
    private String title;
    private String content;
    private Boolean isRead;
    private LocalDateTime readTime;
}
```

### MessageSendDTO

```java
@Data
public class MessageSendDTO {
    @NotNull(message = "消息模板ID不能为空")
    private Long templateId;

    @NotBlank(message = "消息类型不能为空")
    private String messageType;    // INBOX / EMAIL / SMS

    @NotNull(message = "接收用户ID不能为空")
    private Long receiverId;

    private String receiverAddress;  // 邮箱/手机号（EMAIL/SMS 必填）

    @NotBlank(message = "消息主题不能为空")
    private String subject;

    @NotBlank(message = "消息内容不能为空")
    private String content;

    private Map<String, Object> params;  // 模板参数
}
```

### MsgRecordVO

```java
@Data
public class MsgRecordVO {
    private Long id;
    private Long templateId;
    private String messageType;
    private Long receiverId;
    private String receiverAddress;
    private String subject;
    private String content;
    private String sendStatus;
    private LocalDateTime sendTime;
    private String errorMessage;
    private LocalDateTime createdTime;
}
```

### MsgUserInboxVO

```java
@Data
public class MsgUserInboxVO {
    private Long id;
    private Long userId;
    private Long messageId;
    private String title;
    private String content;
    private Boolean isRead;
    private LocalDateTime readTime;
    private LocalDateTime createdTime;
}
```

### MessageController

```java
@RestController
@RequestMapping("/api/v1/messages")
@RequiredArgsConstructor
public class MessageController {

    @PostMapping("/send")
    @PreAuthorize("@ss.hasPermission('system:message:send')")
    public R<Long> sendMessage(@Valid @RequestBody MessageSendDTO dto) {
        // 发送消息,返回消息记录 ID
    }

    @GetMapping("/records")
    @PreAuthorize("@ss.hasPermission('system:message:record:list')")
    public R<PageResult<MsgRecordVO>> listRecords(MsgRecordQueryDTO query) {
        // 分页查询消息记录
    }

    @GetMapping("/records/{id}")
    @PreAuthorize("@ss.hasPermission('system:message:record:query')")
    public R<MsgRecordVO> getRecord(@PathVariable Long id) {
        // 查询消息记录详情
    }

    @GetMapping("/inbox")
    @PreAuthorize("@ss.hasPermission('system:message:inbox:list')")
    public R<PageResult<MsgUserInboxVO>> listInbox(MsgUserInboxQueryDTO query) {
        // 查询当前用户收件箱
    }

    @PutMapping("/inbox/{id}/read")
    @PreAuthorize("@ss.hasPermission('system:message:inbox:read')")
    public R<Void> markAsRead(@PathVariable Long id) {
        // 标记消息已读
    }

    @DeleteMapping("/inbox/{id}")
    @PreAuthorize("@ss.hasPermission('system:message:inbox:delete')")
    public R<Void> deleteInboxMessage(@PathVariable Long id) {
        // 删除收件箱消息
    }
}
```

---

## 前端文件路径

| 文件 | 说明 |
|------|------|
| `ljwx-platform-admin/src/views/system/message/records.vue` | 消息记录管理页面 |
| `ljwx-platform-admin/src/views/system/message/inbox.vue` | 用户收件箱页面 |
| `ljwx-platform-admin/src/api/system/message.ts` | 消息 API 调用封装 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：站内信发送正常,写入 msg_user_inbox
- **AC-03**：邮件发送成功,记录发送状态
- **AC-04**：短信发送成功,记录发送状态
- **AC-05**：消息记录完整,包含发送状态和时间
- **AC-06**：用户收件箱仅显示自己的消息
- **AC-07**：标记已读功能正常
- **AC-08**：删除收件箱消息不影响原始记录
- **AC-09**：发送失败自动重试,达到最大次数标记 FAILURE
- **AC-10**：编译通过,所有 P0 用例通过

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-51-message-records.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-51-01 | 发送站内信 | P0 |
| TC-51-02 | 发送邮件 | P0 |
| TC-51-03 | 发送短信 | P0 |
| TC-51-04 | 查询消息记录 | P0 |
| TC-51-05 | 查询用户收件箱 | P0 |
| TC-51-06 | 标记消息已读 | P0 |
| TC-51-07 | 删除收件箱消息 | P0 |
| TC-51-08 | 发送失败重试 | P0 |

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 消息类型：INBOX / EMAIL / SMS
- 发送状态：PENDING / SUCCESS / FAILURE
- 站内信：必须写入 msg_user_inbox
- 收件箱：仅显示当前用户的消息
- 删除：软删除,不影响原始记录
- 重试：最多 3 次,失败后标记 FAILURE
- 禁止：在 DTO 中声明 `tenantId`

