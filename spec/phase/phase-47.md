---
phase: 47
title: "开放 API 管理 - 应用管理 (Open API - App Management)"
targets:
  backend: true
  frontend: true
depends_on: [46]
bundle_with: [48]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V047__create_open_app.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/OpenApp.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/OpenApiAppController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/OpenApiAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/OpenAppMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/OpenAppMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/OpenAppDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/OpenAppVO.java"
  - "ljwx-platform-web/src/views/system/open-api/app/index.vue"
  - "ljwx-platform-web/src/api/system/open-api-app.ts"
---
# Phase 47 — 开放 API 管理 - 应用管理

| 项目 | 值 |
|-----|---|
| Phase | 47 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-web (前端) |
| Feature | L0-D07-F01 |
| 前置依赖 | Phase 46 (导入导出中心) |
| 测试契约 | `spec/tests/phase-47-open-api-app.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §开放 API 应用表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

## 功能概述

实现开放 API 应用管理,支持:
1. 应用注册
2. 密钥管理
3. HMAC 认证
4. 限流配置

## 数据库契约

### 表结构：sys_open_app

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| app_key | VARCHAR(64) | UK, NOT NULL | 应用标识（自动生成） |
| app_secret | VARCHAR(128) | NOT NULL | 应用密钥（HMAC 签名） |
| app_name | VARCHAR(100) | NOT NULL | 应用名称 |
| app_type | VARCHAR(20) | NOT NULL | INTERNAL / EXTERNAL |
| status | VARCHAR(20) | NOT NULL, INDEX | ENABLED / DISABLED |
| rate_limit | INT | NOT NULL, DEFAULT 100 | 每秒请求数 |
| ip_whitelist | TEXT | | IP 白名单（JSON 数组） |
| expire_time | TIMESTAMP | | 过期时间 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_app_key` (app_key) UNIQUE
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V047__create_open_app.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/open-api/apps | system:openApi:app:add |
| PUT | /api/v1/open-api/apps/{id} | system:openApi:app:edit |
| DELETE | /api/v1/open-api/apps/{id} | system:openApi:app:delete |
| GET | /api/v1/open-api/apps/{id} | system:openApi:app:query |
| GET | /api/v1/open-api/apps | system:openApi:app:list |

## 业务规则

> 格式：BL-47-{序号}：[条件] → [动作] → [结果/异常]

- **BL-47-01**：应用创建 → 自动生成 app_key（UUID 格式）+ app_secret（随机 128 位）
- **BL-47-02**：应用状态 → ENABLED 允许调用 / DISABLED 拒绝调用
- **BL-47-03**：限流配置 → 每秒请求数超限 → 返回 429 Too Many Requests
- **BL-47-04**：IP 白名单 → 请求 IP 不在白名单 → 返回 403 Forbidden
- **BL-47-05**：应用过期 → expire_time < NOW() → 返回 401 Unauthorized
- **BL-47-06**：HMAC 签名验证 → 签名不匹配 → 返回 401 Unauthorized

## 核心组件契约

### OpenApp 实体

```java
@Data
@TableName("sys_open_app")
public class OpenApp extends BaseEntity {
    private String appKey;        // 应用标识（UUID）
    private String appSecret;     // 应用密钥（加密存储）
    private String appName;       // 应用名称
    private String appType;       // INTERNAL / EXTERNAL
    private String status;        // ENABLED / DISABLED
    private Integer rateLimit;    // 每秒请求数
    private String ipWhitelist;   // IP 白名单（JSON 数组）
    private LocalDateTime expireTime;  // 过期时间
}
```

### OpenAppDTO

```java
@Data
public class OpenAppDTO {
    @NotBlank(message = "应用名称不能为空")
    private String appName;

    @NotBlank(message = "应用类型不能为空")
    private String appType;      // INTERNAL / EXTERNAL

    @NotNull(message = "限流配置不能为空")
    @Min(value = 1, message = "限流值至少为 1")
    private Integer rateLimit;

    private String ipWhitelist;  // IP 白名单（JSON 数组字符串）

    private LocalDateTime expireTime;
}
```

### OpenAppVO

```java
@Data
public class OpenAppVO {
    private Long id;
    private String appKey;
    private String appName;
    private String appType;
    private String status;
    private Integer rateLimit;
    private String ipWhitelist;
    private LocalDateTime expireTime;
    private LocalDateTime createdTime;
}
```

### OpenApiAppController

```java
@RestController
@RequestMapping("/api/v1/open-api/apps")
@RequiredArgsConstructor
public class OpenApiAppController {

    @PostMapping
    @PreAuthorize("@ss.hasPermission('system:openApi:app:add')")
    public R<OpenAppVO> create(@Valid @RequestBody OpenAppDTO dto) {
        // 创建应用，自动生成 app_key 和 app_secret
    }

    @PutMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:openApi:app:edit')")
    public R<Void> update(@PathVariable Long id, @Valid @RequestBody OpenAppDTO dto) {
        // 更新应用配置
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:openApi:app:delete')")
    public R<Void> delete(@PathVariable Long id) {
        // 删除应用
    }

    @GetMapping("/{id}")
    @PreAuthorize("@ss.hasPermission('system:openApi:app:query')")
    public R<OpenAppVO> getById(@PathVariable Long id) {
        // 查询应用详情
    }

    @GetMapping
    @PreAuthorize("@ss.hasPermission('system:openApi:app:list')")
    public R<PageResult<OpenAppVO>> list(OpenAppQueryDTO query) {
        // 分页查询应用列表
    }

    @PostMapping("/{id}/regenerate-secret")
    @PreAuthorize("@ss.hasPermission('system:openApi:app:edit')")
    public R<String> regenerateSecret(@PathVariable Long id) {
        // 重新生成 app_secret
    }
}
```

## 前端文件路径

| 文件 | 说明 |
|------|------|
| `ljwx-platform-web/src/views/system/open-api/app/index.vue` | 开放 API 应用管理页面 |
| `ljwx-platform-web/src/api/system/open-api-app.ts` | API 调用封装 |

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：应用 CRUD 正常,app_key 自动生成
- **AC-03**：app_key 唯一性约束生效
- **AC-04**：限流配置正确存储和查询
- **AC-05**：IP 白名单 JSON 格式验证
- **AC-06**：应用密钥重新生成功能正常
- **AC-07**：前端页面正常显示和操作
- **AC-08**：编译通过,所有 P0 用例通过

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-47-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-47-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-47-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-47-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-47-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-47-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-47-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-47-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-47-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-47-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
