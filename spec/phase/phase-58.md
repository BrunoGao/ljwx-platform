---
phase: 58
title: "运营仪表盘 + 计量计费 + 帮助中心 (Operations Dashboard + Billing + Help Center)"
targets:
  backend: true
  frontend: true
depends_on: [57]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V065__create_billing_and_help.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/BillUsageRecord.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/HelpDoc.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/mapper/BillUsageRecordMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/mapper/HelpDocMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/BillUsageRecordMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/HelpDocMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/BillUsageAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/HelpDocAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/OperationsDashboardService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/BillingController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/HelpDocController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/OperationsDashboardController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/job/DailyUsageStatJob.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/billing/BillingQueryDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/help/HelpDocCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/help/HelpDocUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/billing/UsageRecordVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/billing/TenantUsageSummaryVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/billing/DailyStatVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/ops/OperationsDashboardVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/help/HelpDocVO.java"
  - "ljwx-platform-admin/src/api/billing/billing.ts"
  - "ljwx-platform-admin/src/api/ops/dashboard.ts"
  - "ljwx-platform-admin/src/api/help/help-doc.ts"
  - "ljwx-platform-admin/src/views/ops/dashboard/index.vue"
  - "ljwx-platform-admin/src/views/billing/usage/index.vue"
  - "ljwx-platform-admin/src/views/system/help/index.vue"
  - "ljwx-platform-admin/src/components/HelpButton.vue"
---
# Phase 58 — 运营仪表盘 + 计量计费 + 帮助中心

| 项目 | 值 |
|-----|---|
| Phase | 58 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L1-D04 计量计费 + L1-D05 运营看板 + L1-D06 帮助中心 |
| 前置依赖 | Phase 57 (移动端+i18n) |
| 测试契约 | `spec/tests/phase-58-ops-billing-help.tests.yml` |
| 优先级 | 🟢 **P2** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §审计字段
- `spec/03-api.md` — §REST 规范
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`
- `docs/reference/list.md` — §L1-D04 计量计费、§L1-D05 运营看板、§L1-D06 帮助中心

## 功能概述

**问题**：
- 平台运营方无法直观了解各租户的用量趋势和资源消耗
- 租户超额使用无法及时感知和干预
- 新用户上手困难，缺乏上下文关联的帮助文档

**解决方案**：
1. **计量计费**：Quartz 每日定时任务聚合 sys_operation_log/sys_login_log/sys_file 按 tenant_id 统计，写入 bill_usage_record
2. **运营仪表盘**：基于 bill_usage_record + sys_tenant 构建全局运营看板（DAU/MAU、存储用量、API 调用、即将过期预警）
3. **帮助中心**：帮助文档管理 + 前端悬浮 "?" 按当前路由匹配帮助内容

## 数据库契约

### 表结构：bill_usage_record（用量统计）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID |
| metric_type | VARCHAR(50) | NOT NULL | 指标类型（USER_COUNT/STORAGE_MB/API_CALLS/LOGIN_COUNT/FILE_COUNT） |
| usage_value | DECIMAL(18,4) | NOT NULL, DEFAULT 0 | 用量值 |
| record_date | DATE | NOT NULL | 统计日期（每日一条） |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**：
- `uk_usage_tenant_metric_date (tenant_id, metric_type, record_date) WHERE deleted = FALSE` UNIQUE
- `idx_usage_tenant_date (tenant_id, record_date DESC)`
- `idx_usage_metric_date (metric_type, record_date DESC)` — 全平台聚合查询

### 表结构：sys_help_doc（帮助文档）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0 | 租户 ID（0=全局文档，对所有租户可见） |
| doc_key | VARCHAR(100) | NOT NULL | 文档唯一标识 |
| title | VARCHAR(200) | NOT NULL | 文档标题 |
| content | TEXT | NOT NULL | Markdown 正文 |
| category | VARCHAR(50) | NOT NULL | 分类（如 user/role/menu/dept/workflow/...） |
| route_match | VARCHAR(500) | NULL | 关联前端路由（如 `/system/user`，支持通配符） |
| sort_order | INT | NOT NULL, DEFAULT 0 | 排序 |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 状态：1 启用，0 停用 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

> **说明**：`tenant_id = 0` 代表平台级全局文档，对所有租户可见；超管可维护全局文档，租户管理员可维护本租户自定义文档（tenant_id = 本租户 ID）。

**索引**：
- `uk_helpdoc_tenant_key (tenant_id, doc_key) WHERE deleted = FALSE` UNIQUE
- `idx_helpdoc_tenant_category (tenant_id, category, status) WHERE deleted = FALSE`
- `idx_helpdoc_route (route_match) WHERE deleted = FALSE AND route_match IS NOT NULL`

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V065__create_billing_and_help.sql` | 建 bill_usage_record + sys_help_doc + 全部索引 |

**禁止**：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

### 计量计费 API

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/billing/usage | system:billing:list | — | Result\<List\<UsageRecordVO\>\> | 用量记录（tenantId+日期范围） |
| GET | /api/v1/billing/summary | system:billing:list | — | Result\<List\<TenantUsageSummaryVO\>\> | 租户用量汇总 |

### 运营仪表盘 API

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/ops/dashboard | system:ops:dashboard | — | Result\<OperationsDashboardVO\> | 全局运营仪表盘数据（仅超管可访问） |

### 帮助中心 API

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/help-docs | system:help:list | — | Result\<List\<HelpDocVO\>\> | 列表（按 category 过滤） |
| GET | /api/v1/help-docs/{id} | system:help:query | — | Result\<HelpDocVO\> | 详情 |
| GET | /api/v1/help-docs/route | — | — | Result\<HelpDocVO\> | 按路由匹配文档（无需鉴权） |
| POST | /api/v1/help-docs | system:help:add | HelpDocCreateDTO | Result\<Long\> | 创建 |
| PUT | /api/v1/help-docs/{id} | system:help:edit | HelpDocUpdateDTO | Result\<Void\> | 更新 |
| DELETE | /api/v1/help-docs/{id} | system:help:delete | — | Result\<Void\> | 删除 |

## DTO / VO 契约

### BillingQueryDTO（用量查询请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| startDate | LocalDate | @NotNull | 查询开始日期 |
| endDate | LocalDate | @NotNull | 查询结束日期 |
| metricType | String | — | 指标类型过滤（可选，不传则返回全部类型） |

**禁止字段**：`tenantId`（由 TenantLineInterceptor 自动注入）

### UsageRecordVO（单条用量记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| metricType | String | 指标类型（USER_COUNT/STORAGE_MB/API_CALLS/LOGIN_COUNT/FILE_COUNT） |
| usageValue | BigDecimal | 用量值 |
| recordDate | LocalDate | 统计日期 |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

> `tenantId` 不在此 VO 中暴露（租户用户只能查自身，超管通过 `/billing/summary` 的 `TenantUsageSummaryVO` 查跨租户汇总）。

### DailyStatVO（每日统计数据点）

| 字段 | 类型 | 说明 |
|------|------|------|
| date | LocalDate | 统计日期 |
| count | Long | 活跃用户数（当日有登录记录的去重用户数） |

### HelpDocCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| docKey | String | @NotBlank, @Size(max=100), @Pattern(regexp="^[a-z][a-z0-9_-]*$") | 文档标识 |
| title | String | @NotBlank, @Size(max=200) | 标题 |
| content | String | @NotBlank | Markdown 正文 |
| category | String | @NotBlank, @Size(max=50) | 分类 |
| routeMatch | String | @Size(max=500) | 关联路由 |
| sortOrder | Integer | @Min(0) | 排序 |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### HelpDocUpdateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| title | String | @NotBlank, @Size(max=200) | 标题 |
| content | String | @NotBlank | Markdown 正文 |
| category | String | @NotBlank, @Size(max=50) | 分类 |
| routeMatch | String | @Size(max=500) | 关联路由 |
| sortOrder | Integer | @Min(0) | 排序 |
| status | Integer | @NotNull, @Min(0), @Max(1) | 状态 |

**禁止字段**：`id`、`docKey`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

> `docKey` 一旦创建不可修改（唯一标识，变更需删除重建）。

### TenantUsageSummaryVO

> **访问限制**：此 VO 仅用于超管（tenant_id = 0）可访问的接口（`/api/v1/billing/summary`、`/api/v1/ops/dashboard`），普通租户用户不可获取其他租户的用量汇总。`tenantId` 字段在此场景下合理暴露，但必须通过 Service 层鉴权保障（见 BL-58-07）。

| 字段 | 类型 | 说明 |
|------|------|------|
| tenantId | Long | 租户 ID（仅超管接口返回，普通用户接口不包含此字段） |
| tenantName | String | 租户名称 |
| expireTime | LocalDateTime | 到期时间 |
| userCount | Long | 最新用户数 |
| storageMb | BigDecimal | 最新存储用量（MB） |
| apiCallsTotal | Long | 近 30 天 API 调用总量 |
| loginCountLast30d | Long | 近 30 天登录次数 |
| isExpiringSoon | Boolean | 是否即将到期（30 天内） |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

> `tenantId` 在 VO 中不属于禁止字段（VO 禁止字段仅为：deleted/createdBy/updatedBy/version）。此 VO 专用于超管接口，`tenantId` 是必要的租户标识字段。

### OperationsDashboardVO

| 字段 | 类型 | 说明 |
|------|------|------|
| totalTenants | Long | 总租户数 |
| activeTenants | Long | 活跃租户数（近 7 天有登录） |
| expiringSoon | List\<TenantUsageSummaryVO\> | 即将到期租户列表（30 天内） |
| dailyActiveUsers | List\<DailyStatVO\> | 近 30 天 DAU 趋势 |
| totalStorageMb | BigDecimal | 全平台总存储用量 |
| totalApiCallsToday | Long | 今日 API 调用总量 |

### HelpDocVO

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| docKey | String | 文档标识 |
| title | String | 标题 |
| content | String | Markdown 正文 |
| category | String | 分类 |
| routeMatch | String | 关联路由 |
| sortOrder | Integer | 排序 |
| status | Integer | 状态 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

## 核心组件契约

### DailyUsageStatJob（Quartz 定时任务）

```java
/**
 * 每日用量统计 Job
 * 执行时间：每天凌晨 02:00（低峰期）
 * Cron: 0 0 2 * * ?
 */
@Component
public class DailyUsageStatJob implements Job {

    @Override
    public void execute(JobExecutionContext context) {
        LocalDate yesterday = LocalDate.now().minusDays(1);

        // 1. 统计各租户用户数（从 sys_user 按 tenant_id 聚合）
        statUserCount(yesterday);

        // 2. 统计各租户文件存储量（从 sys_file 按 tenant_id 聚合 file_size）
        statStorageMb(yesterday);

        // 3. 统计各租户 API 调用量（从 sys_operation_log 按 tenant_id 计数）
        statApiCalls(yesterday);

        // 4. 统计各租户登录次数（从 sys_login_log 按 tenant_id 计数）
        statLoginCount(yesterday);
    }

    // 使用 INSERT ... ON CONFLICT DO UPDATE 实现幂等写入
    private void statUserCount(LocalDate date) {
        // SQL: INSERT INTO bill_usage_record (tenant_id, metric_type, usage_value, record_date, ...)
        //      SELECT tenant_id, 'USER_COUNT', COUNT(*), #{date}, ...
        //      FROM sys_user WHERE deleted = FALSE
        //      GROUP BY tenant_id
        //      ON CONFLICT (tenant_id, metric_type, record_date)
        //      WHERE deleted = FALSE
        //      DO UPDATE SET usage_value = EXCLUDED.usage_value, updated_time = NOW()
    }
}
```

### OperationsDashboardService

```java
@Service
@RequiredArgsConstructor
public class OperationsDashboardService {

    public OperationsDashboardVO getDashboard() {
        // 数据来源：bill_usage_record + sys_tenant
        // 不使用 Prometheus（指标不含 tenantId，不适合租户维度查询）
        return OperationsDashboardVO.builder()
            .totalTenants(tenantMapper.countAll())
            .activeTenants(usageMapper.countActiveTenants(7))  // 近 7 天有登录
            .expiringSoon(tenantMapper.listExpiringSoon(30))
            .dailyActiveUsers(usageMapper.getDailyActiveUsers(30))
            .totalStorageMb(usageMapper.sumStorageMb())
            .totalApiCallsToday(usageMapper.sumApiCallsToday())
            .build();
    }
}
```

### 帮助中心前端集成（HelpButton.vue）

```vue
<!-- 悬浮帮助按钮，按当前路由匹配文档 -->
<template>
  <el-tooltip :content="t('common.help')" placement="left">
    <el-button
      class="help-btn"
      circle
      @click="openHelp"
    >
      ?
    </el-button>
  </el-tooltip>

  <el-drawer v-model="visible" :title="doc?.title" size="40%">
    <div v-if="doc" v-html="renderedContent" class="help-content" />
    <el-empty v-else :description="t('help.noDoc')" />
  </el-drawer>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router'
import { getHelpDocByRoute } from '@/api/help/help-doc'
import { marked } from 'marked'

const route = useRoute()
const visible = ref(false)
const doc = ref<HelpDoc | null>(null)

const openHelp = async () => {
  doc.value = await getHelpDocByRoute(route.path)
  visible.value = true
}

const renderedContent = computed(() =>
  doc.value ? marked(doc.value.content) : ''
)
</script>
```

### HelpDocController 类

```java
@RestController
@RequestMapping("/api/v1/help-docs")
@RequiredArgsConstructor
public class HelpDocController {

    @GetMapping
    @PreAuthorize("hasAuthority('system:help:list')")
    public Result<List<HelpDocVO>> list(@RequestParam(required = false) String category) { ... }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('system:help:query')")
    public Result<HelpDocVO> getById(@PathVariable Long id) { ... }

    // 公开接口：无需鉴权，在 SecurityConfig 中配置 permitAll
    // .requestMatchers(HttpMethod.GET, "/api/v1/help-docs/route").permitAll()
    @GetMapping("/route")
    public Result<HelpDocVO> getByRoute(@RequestParam String path) { ... }

    @PostMapping
    @PreAuthorize("hasAuthority('system:help:add')")
    public Result<Long> create(@Valid @RequestBody HelpDocCreateDTO dto) { ... }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('system:help:edit')")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody HelpDocUpdateDTO dto) { ... }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('system:help:delete')")
    public Result<Void> delete(@PathVariable Long id) { ... }
}
```

> **注意**：`/api/v1/help-docs/route` 通过 Spring Security 配置 `permitAll` 放行，**不**使用 `@PreAuthorize`，避免抛出 403。SecurityConfig 中需在 JWT 过滤器前配置此路径白名单。

## 业务规则

> 格式：BL-58-{序号}：[条件] → [动作] → [结果/异常]

- **BL-58-01**：DailyUsageStatJob 使用 `ON CONFLICT DO UPDATE` 实现幂等写入 → 每日重复执行不产生重复数据
- **BL-58-02**：运营仪表盘数据来源必须是 `bill_usage_record`（PostgreSQL），**禁止**从 Prometheus 查询租户维度数据（高基数问题）
- **BL-58-03**：`GET /api/v1/help-docs/route?path=...` 无需鉴权 → 任何登录用户可访问帮助文档
- **BL-58-04**：帮助文档 `route_match` 支持精确匹配和前缀匹配（`/system/user` 匹配 `/system/user/list`）→ 优先精确匹配
- **BL-58-05**：租户用量超过套餐配额时（USER_COUNT > max_user_count 等）→ 通过消息中台发送告警通知给租户管理员 → 不强制阻断操作（P2 阶段仅告警）
- **BL-58-06**：即将到期预警（30 天内到期）→ 在运营仪表盘醒目展示 + 每周通过消息中台通知超管
- **BL-58-07**：调用 `GET /api/v1/billing/summary` 和 `GET /api/v1/ops/dashboard` 时 → Service 层验证 SecurityContext 中当前用户 tenantId == 0（平台超管身份）→ 非超管用户抛出 AccessDeniedException（响应 403），不返回任何跨租户数据

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-58-ops-billing-help.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-58-01 | 无 Token → 401 | P0 |
| TC-58-02 | 无 system:billing:list 或 system:ops:dashboard 权限 → 403 | P0 |
| TC-58-03 | DailyUsageStatJob 执行，bill_usage_record 写入 | P0 |
| TC-58-04 | DailyUsageStatJob 重复执行，数据幂等（不重复） | P0 |
| TC-58-05 | 运营仪表盘接口返回正确数据 | P0 |
| TC-58-06 | 帮助文档按路由匹配（精确匹配优先于前缀匹配） | P0 |
| TC-58-07 | 帮助文档路由接口无需鉴权 | P0 |
| TC-58-08 | 帮助文档 docKey 重复 → 409 | P0 |
| TC-58-09 | V065 无 IF NOT EXISTS，含全部审计字段 | P0 |
| TC-58-10 | 跨租户：超管可查所有租户用量，普通用户只能查本租户 | P0 |

## 验收条件

- **AC-01**：V065 建 bill_usage_record + sys_help_doc + 全部索引，无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`（除 /help-docs/route 公开接口）；`/billing/summary` 和 `/ops/dashboard` Service 层额外验证超管身份（BL-58-07）
- **AC-03**：DailyUsageStatJob Cron 配置正确（每日 02:00），幂等写入
- **AC-04**：运营仪表盘数据源为 PostgreSQL bill_usage_record，不使用 Prometheus
- **AC-05**：HelpButton 组件集成到 Admin 布局，按路由动态加载帮助文档
- **AC-06**：即将到期租户预警在仪表盘醒目展示
- **AC-07**：编译通过，所有 P0 用例通过

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT，禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:billing:list')`、`hasAuthority('system:ops:dashboard')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · 运营数据从 Prometheus 查询（高基数）
- DAG 依赖：core ← {security, data} ← web ← app
- bill_usage_record 写入必须幂等（`ON CONFLICT DO UPDATE`）
- 帮助文档公开接口：`/api/v1/help-docs/route` 不需要 @PreAuthorize（通过 permitAll 配置放行）
