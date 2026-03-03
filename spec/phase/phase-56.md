---
phase: 56
title: "AI 智能运维助手 (AI Operations Assistant)"
targets:
  backend: true
  frontend: true
depends_on: [55]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V064__create_ai_config_and_log.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/AiConfig.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/AiConversationLog.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/mapper/AiConfigMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/mapper/AiConversationLogMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/AiConfigMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/AiConversationLogMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/AiChatAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/AiConfigAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/AiChatController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/AiConfigController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/ai/tool/MonitorTool.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/ai/tool/LogQueryTool.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/ai/tool/JobQueryTool.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/ai/tool/OnlineUserTool.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/ai/AiChatDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/ai/AiConfigUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/ai/AiConversationLogQueryDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/ai/AiChatVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/ai/AiConversationLogVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/ai/AiConfigVO.java"
  - "ljwx-platform-admin/src/api/ai/ai-chat.ts"
  - "ljwx-platform-admin/src/api/ai/ai-config.ts"
  - "ljwx-platform-admin/src/views/monitor/ai-assistant/index.vue"
  - "ljwx-platform-admin/src/views/system/ai-config/index.vue"
---
# Phase 56 — AI 智能运维助手 (AI Operations Assistant)

| 项目 | 值 |
|-----|---|
| Phase | 56 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L5-D04 AI 智能助手 |
| 前置依赖 | Phase 55 (报表引擎) |
| 测试契约 | `spec/tests/phase-56-ai-assistant.tests.yml` |
| 优先级 | 🟢 **P2** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §JSONB 字段规范、§审计字段
- `spec/03-api.md` — §REST 规范
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`
- `docs/reference/list.md` — §L5-D04 AI 智能助手

## 功能概述

**问题**：运维人员需要同时查阅多个监控面板（日志、指标、任务、在线用户）来诊断系统问题，效率低且依赖经验。

**解决方案**：基于 Spring AI + MCP Tool 构建只读运维 AI Agent，支持：
1. **自然语言查询**：将运维问题转化为平台工具调用（查日志、看任务、查在线用户等）
2. **MCP Tool 封装**：暴露平台只读 API 为 AI 可调用的 Tool（4 类工具）
3. **多模型支持**：通过 Spring AI ChatModel 抽象层，sys_config 配置模型提供商和 API Key
4. **全量审计**：每次对话（含 Tool 调用链）写入 sys_ai_conversation_log
5. **RBAC 约束**：Agent 独立权限上下文，仅持有只读权限

## 数据库契约

### 表结构：sys_ai_config（AI 配置）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID（0=全局配置） |
| provider | VARCHAR(50) | NOT NULL | 模型提供商（OPENAI / TONGYI / DEEPSEEK） |
| model_name | VARCHAR(100) | NOT NULL | 模型名称（如 gpt-4o） |
| api_key_encrypted | TEXT | NOT NULL | 加密存储的 API Key |
| base_url | VARCHAR(500) | NULL | 自定义 API Base URL（可选） |
| temperature | DECIMAL(3,2) | NOT NULL, DEFAULT 0.70 | 温度参数（0.00-1.00） |
| max_tokens | INT | NOT NULL, DEFAULT 2048 | 最大 Token 数 |
| enabled | BOOLEAN | NOT NULL, DEFAULT TRUE | 是否启用 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**：
- `uk_ai_config_tenant (tenant_id) WHERE deleted = FALSE AND enabled = TRUE` UNIQUE

### 表结构：sys_ai_conversation_log（AI 对话日志）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID |
| user_id | BIGINT | NOT NULL, DEFAULT 0 | 操作用户 ID |
| session_id | VARCHAR(64) | NOT NULL | 会话 ID（同一轮对话相同） |
| question | TEXT | NOT NULL | 用户提问 |
| answer | TEXT | NOT NULL | AI 回答 |
| tool_calls | JSONB | NULL | Tool 调用链（调用名称、参数、结果） |
| tokens_used | INT | NOT NULL, DEFAULT 0 | 消耗 Token 数 |
| duration_ms | INT | NOT NULL, DEFAULT 0 | 响应耗时（毫秒） |
| model_name | VARCHAR(100) | NOT NULL | 使用的模型名称 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**：
- `idx_ai_log_tenant_user (tenant_id, user_id, created_time DESC)`
- `idx_ai_log_session (session_id)`

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V064__create_ai_config_and_log.sql` | 建 sys_ai_config + sys_ai_conversation_log + 索引 |

**禁止**：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

### AI 对话 API

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| POST | /api/v1/ai/chat | system:ai:chat | AiChatDTO | Result\<AiChatVO\> | 发送消息 |
| GET | /api/v1/ai/conversations | system:ai:log:list | — | Result\<PageResult\<AiConversationLogVO\>\> | 对话历史 |

### AI 配置 API

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/ai/config | system:ai:config:query | — | Result\<AiConfigVO\> | 查看配置（API Key 脱敏） |
| PUT | /api/v1/ai/config | system:ai:config:edit | AiConfigUpdateDTO | Result\<Void\> | 更新配置（含 API Key 轮换） |

## DTO / VO 契约

### AiChatDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| sessionId | String | @Size(max=64), @Pattern(regexp="[a-zA-Z0-9_-]+") | 会话 ID（空则生成新会话，仅允许字母数字下划线短横线） |
| message | String | @NotBlank, @Size(min=1, max=2000) | 用户提问（1-2000 字符） |

**禁止字段**：`id`、`tenantId`、`userId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

> `AiChatDTO` 是轻量请求对象，无对应持久化实体，`sessionId`/`message` 是唯一有效字段；其余禁止字段列表按标准 DTO 规范列出，防止客户端注入审计字段。

### AiChatVO

| 字段 | 类型 | 说明 |
|------|------|------|
| sessionId | String | 会话 ID |
| answer | String | AI 回答 |
| toolCalls | List | Tool 调用摘要（名称+参数，不含原始结果） |
| tokensUsed | Integer | 消耗 Token 数 |
| durationMs | Long | 响应耗时 |

### AiConversationLogVO

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| sessionId | String | 会话 ID |
| question | String | 用户提问 |
| answer | String | AI 回答 |
| toolCallSummary | List\<String\> | Tool 调用名称摘要（不含原始参数和返回值，避免泄露内部数据） |
| tokensUsed | Integer | 消耗 Token 数 |
| durationMs | Long | 响应耗时（毫秒） |
| modelName | String | 使用的模型名称 |
| createdTime | LocalDateTime | 创建时间 |

**禁止字段**：`toolCalls`（原始 JSONB，含参数和返回值）、`deleted`、`createdBy`、`updatedBy`、`version`

### AiConfigUpdateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| provider | String | @NotBlank, @Pattern(regexp="OPENAI\|TONGYI\|DEEPSEEK") | 提供商 |
| modelName | String | @NotBlank, @Size(max=100), @Pattern(regexp="[a-zA-Z0-9._-]+") | 模型名称（仅允许字母数字点下划线短横线） |
| apiKey | String | @NotBlank, @Size(min=20, max=500) | API Key（明文，后端加密存储，20-500 字符） |
| baseUrl | String | @Size(max=500), @Pattern(regexp="https?://.*") | 自定义 Base URL（必须以 http:// 或 https:// 开头） |
| temperature | BigDecimal | @DecimalMin("0.0"), @DecimalMax("1.0") | 温度 |
| maxTokens | Integer | @Min(256), @Max(8192) | 最大 Token 数 |

**禁止字段**：`id`、`tenantId`、`apiKeyEncrypted`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### AiConfigVO

| 字段 | 类型 | 说明 |
|------|------|------|
| provider | String | 提供商 |
| modelName | String | 模型名称 |
| apiKeyMasked | String | 脱敏 API Key（`sk-***...***xxxx`） |
| baseUrl | String | Base URL |
| temperature | BigDecimal | 温度 |
| maxTokens | Integer | 最大 Token 数 |
| enabled | Boolean | 是否启用 |

**禁止字段**：`apiKeyEncrypted`、`deleted`、`createdBy`、`updatedBy`、`version`

## 核心组件契约

### MCP Tool 清单（只读）

| Tool 类 | 工具名称 | 描述 | 权限约束 |
|---------|----------|------|----------|
| MonitorTool | `getServerStatus` | 获取 JVM/CPU/内存/Redis 状态 | 仅 system:monitor:server |
| MonitorTool | `getCacheStats` | 获取 Caffeine 缓存命中率 | 仅 system:monitor:cache |
| LogQueryTool | `queryOperationLogs` | 按时间/用户/模块查询操作日志 | 仅 system:operlog:list |
| LogQueryTool | `queryLoginLogs` | 按时间/用户查询登录日志 | 仅 system:loginlog:list |
| JobQueryTool | `listScheduledJobs` | 列出定时任务及状态 | 仅 system:job:list |
| JobQueryTool | `getJobLogs` | 获取任务最近执行日志 | 仅 system:taskLog:list |
| OnlineUserTool | `getOnlineUserCount` | 获取当前在线用户数 | 仅 system:online:list |

### Service 类

```java
@Service
@RequiredArgsConstructor
public class AiChatAppService {

    private final ChatModel chatModel;
    private final AiConversationLogMapper logMapper;
    private final AiConfigAppService configService;

    /**
     * 发送消息并获取 AI 回答
     * 安全约束：
     * 1. Agent 使用只读 Tool，无写操作权限
     * 2. 每次对话全量写入 sys_ai_conversation_log（含 tool_calls JSONB）
     * 3. API Key 从 sys_ai_config 动态加载，不硬编码
     */
    public AiChatVO chat(AiChatDTO dto) {
        // 1. 加载 AI 配置
        AiConfig config = configService.getActiveConfig();

        // 2. 构建 Tool 列表（仅只读 Tool）
        List<FunctionCallback> tools = buildReadOnlyTools();

        // 3. 调用 ChatModel
        long start = System.currentTimeMillis();
        ChatResponse response = chatModel.call(
            new Prompt(dto.getMessage(), ToolCallingOptions.builder()
                .tools(tools)
                .temperature(config.getTemperature().doubleValue())
                .maxTokens(config.getMaxTokens())
                .build()));

        // 4. 写入审计日志
        saveConversationLog(dto, response, System.currentTimeMillis() - start);

        return buildChatVO(dto.getSessionId(), response);
    }
}
```

### Controller 类

```java
@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
public class AiChatController {

    @PostMapping("/chat")
    @PreAuthorize("hasAuthority('system:ai:chat')")
    public Result<AiChatVO> chat(@Valid @RequestBody AiChatDTO dto) { ... }

    @GetMapping("/conversations")
    @PreAuthorize("hasAuthority('system:ai:log:list')")
    public Result<PageResult<AiConversationLogVO>> conversations(AiConversationLogQueryDTO query) { ... }
}

@RestController
@RequestMapping("/api/v1/ai/config")
@RequiredArgsConstructor
public class AiConfigController {

    @GetMapping
    @PreAuthorize("hasAuthority('system:ai:config:query')")
    public Result<AiConfigVO> getConfig() { ... }

    @PutMapping
    @PreAuthorize("hasAuthority('system:ai:config:edit')")
    public Result<Void> updateConfig(@Valid @RequestBody AiConfigUpdateDTO dto) { ... }
}
```

## 业务规则

> 格式：BL-56-{序号}：[条件] → [动作] → [结果/异常]

- **BL-56-01**：AI 对话时，Agent 仅持有只读权限（通过 SecurityContext 模拟只读角色）→ 尝试调用写操作 Tool → 返回 403
- **BL-56-02**：每次 AI 对话必须写入 sys_ai_conversation_log（包含 tool_calls JSONB）→ 同步写入，写日志失败时记录错误日志但不阻断对话响应（降级策略）
- **BL-56-03**：API Key 必须加密存储（AES），查询时 `apiKeyMasked` 脱敏显示 → 原始 Key 不在任何 VO 中暴露
- **BL-56-04**：AI 配置未启用时调用 /chat → 返回 503 "AI 功能未启用"
- **BL-56-05**：sessionId 为空时自动生成 UUID → 返回 AiChatVO 中的 sessionId 供客户端续用
- **BL-56-06**：Tool 调用结果包含租户敏感数据时，TenantLineInterceptor 已在底层查询时隔离，Agent 不需要额外处理

## 模型切换配置

**配置源**：`sys_ai_config` 表（单一真源，SSOT）

`AiConfigAppService` 从 `sys_ai_config` 表动态加载配置，支持租户级覆盖：
- `tenant_id = 0`：全局默认配置（平台级）
- `tenant_id != 0`：租户自定义配置（优先级高于全局）

Spring AI 通过 `AiConfigAppService` 动态构建 ChatModel 实例：

```java
@Service
public class AiConfigAppService {
    public ChatModel buildChatModel() {
        AiConfig config = getActiveConfig(); // 从 sys_ai_config 表查询
        return switch (config.getProvider()) {
            case "OPENAI" -> new OpenAiChatModel(
                OpenAiApi.builder()
                    .apiKey(decrypt(config.getApiKeyEncrypted()))
                    .baseUrl(config.getBaseUrl())
                    .build(),
                OpenAiChatOptions.builder()
                    .model(config.getModelName())
                    .temperature(config.getTemperature().doubleValue())
                    .maxTokens(config.getMaxTokens())
                    .build()
            );
            // ... 其他提供商
        };
    }
}
```

**禁止**：不使用 `sys_config` 表或环境变量作为配置源（避免多源冲突）。

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-56-ai-assistant.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-56-01 | 无 Token → 401 | P0 |
| TC-56-02 | 无 system:ai:chat 权限 → 403 | P0 |
| TC-56-03 | AI 配置未启用 → 503 | P0 |
| TC-56-04 | 正常对话，写入 sys_ai_conversation_log | P0 |
| TC-56-05 | 对话日志含 tool_calls JSONB | P0 |
| TC-56-06 | 获取配置，API Key 脱敏 | P0 |
| TC-56-07 | 更新配置，API Key 加密存储 | P0 |
| TC-56-08 | 跨租户隔离：Tool 查询结果仅含本租户数据 | P0 |
| TC-56-09 | V064 无 IF NOT EXISTS，含全部审计字段 | P0 |

## 验收条件

- **AC-01**：V064 建 sys_ai_config + sys_ai_conversation_log，无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`
- **AC-03**：API Key 加密存储，VO 中仅暴露脱敏版本
- **AC-04**：AI 对话全量写入审计日志（含 tool_calls）
- **AC-05**：Agent 仅持有只读工具，无写操作权限
- **AC-06**：编译通过，所有 P0 用例通过

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT，禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:ai:chat')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · API Key 明文存储 · Agent 调用写操作 Tool
- DAG 依赖：core ← {security, data} ← web ← app
- AI 对话必须全量审计（D4 要求）
- Spring AI 版本：与 Spring Boot 3.5.x 兼容的最新版本
