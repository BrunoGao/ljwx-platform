---
phase: 50
title: "消息中台 - 模板管理 (Message Center - Template)"
targets:
  backend: true
  frontend: true
depends_on: [49]
bundle_with: [51]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V050__create_msg_template.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/MsgTemplate.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/MsgTemplateController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/MsgTemplateService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/MsgTemplateMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/MsgTemplateMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/MsgTemplateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/MsgTemplateVO.java"
  - "ljwx-platform-web/src/views/message/template/index.vue"
  - "ljwx-platform-web/src/api/message/template.ts"
---
# Phase 50 — 消息中台 - 模板管理

| 项目 | 值 |
|-----|---|
| Phase | 50 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-web (前端) |
| Feature | L0-D07-F01 |
| 前置依赖 | Phase 49 (消息中台 - 站内信) |
| 测试契约 | `spec/tests/phase-50-msg-template.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §消息模板表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

## 功能概述

实现消息模板管理,支持:
1. 模板 CRUD
2. 变量替换
3. 多渠道支持
4. 模板版本

## 数据库契约

### 表结构：msg_template

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| template_code | VARCHAR(50) | UK, NOT NULL, INDEX | 模板编码 |
| template_name | VARCHAR(100) | NOT NULL | 模板名称 |
| template_type | VARCHAR(20) | NOT NULL, INDEX | INBOX / EMAIL / SMS |
| subject | VARCHAR(200) | | 邮件主题 |
| content | TEXT | NOT NULL | 模板内容 |
| variables | TEXT | | JSON 数组, 变量列表 |
| status | VARCHAR(20) | NOT NULL, INDEX | ENABLED / DISABLED |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_template_code` (template_code) UNIQUE
- `idx_template_type` (template_type)
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V050__create_msg_template.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/messages/templates | system:message:template:add |
| PUT | /api/v1/messages/templates/{id} | system:message:template:edit |
| DELETE | /api/v1/messages/templates/{id} | system:message:template:delete |
| GET | /api/v1/messages/templates/{id} | system:message:template:query |
| GET | /api/v1/messages/templates | system:message:template:list |

## 业务规则

- BL-50-01: 模板变量 → {{variable_name}} 格式 (Mustache 风格)
- BL-50-02: 变量替换 → 运行时替换
- BL-50-03: 模板类型 → INBOX/EMAIL/SMS
- BL-50-04: 模板状态 → ENABLED/DISABLED

## 核心组件契约

### MsgTemplate 实体

```java
@Data
@TableName("msg_template")
public class MsgTemplate extends BaseEntity {
    private String templateCode;   // 模板编码
    private String templateName;   // 模板名称
    private String templateType;   // INBOX / EMAIL / SMS
    private String subject;        // 邮件主题
    private String content;        // 模板内容
    private String variables;      // JSON 数组, 变量列表
    private String status;         // ENABLED / DISABLED
}
```

### MsgTemplateDTO

```java
@Data
public class MsgTemplateDTO {
    @NotBlank(message = "模板编码不能为空")
    @Size(max = 50, message = "模板编码长度不能超过50")
    private String templateCode;

    @NotBlank(message = "模板名称不能为空")
    @Size(max = 100, message = "模板名称长度不能超过100")
    private String templateName;

    @NotBlank(message = "模板类型不能为空")
    private String templateType;  // INBOX / EMAIL / SMS

    @Size(max = 200, message = "邮件主题长度不能超过200")
    private String subject;

    @NotBlank(message = "模板内容不能为空")
    private String content;

    private String variables;     // JSON 数组

    @NotBlank(message = "状态不能为空")
    private String status;        // ENABLED / DISABLED
}
```

### MsgTemplateVO

```java
@Data
public class MsgTemplateVO {
    private Long id;
    private String templateCode;
    private String templateName;
    private String templateType;
    private String subject;
    private String content;
    private String variables;
    private String status;
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
}
```

### MsgTemplateController

```java
@RestController
@RequestMapping("/api/v1/messages/templates")
@RequiredArgsConstructor
public class MsgTemplateController {

    @PostMapping
    @PreAuthorize("@ss.hasPermission('system:message:template:add')")
    public R<Long> create(@Valid @RequestBody MsgTemplateDTO dto) {
        // 创建模板
    }

    @PutMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:message:template:edit')")
    public R<Void> update(@PathVariable Long id, @Valid @RequestBody MsgTemplateDTO dto) {
        // 更新模板
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:message:template:delete')")
    public R<Void> delete(@PathVariable Long id) {
        // 删除模板
    }

    @GetMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:message:template:query')")
    public R<MsgTemplateVO> getById(@PathVariable Long id) {
        // 查询模板详情
    }

    @GetMapping
    @PreAuthorize("@ss.hasPermission('system:message:template:list')")
    public R<PageResult<MsgTemplateVO>> list(MsgTemplateQueryDTO query) {
        // 分页查询模板列表
    }
}
```

## 前端文件路径

| 文件 | 说明 |
|------|------|
| `ljwx-platform-web/src/views/message/template/index.vue` | 消息模板管理页面 |
| `ljwx-platform-web/src/api/message/template.ts` | API 调用封装 |

## 验收条件

- AC-01: 模板 CRUD 正常
- AC-02: 变量替换正确
- AC-03: 多渠道支持
- AC-04: 模板版本管理
