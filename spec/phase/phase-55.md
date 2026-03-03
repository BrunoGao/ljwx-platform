---
phase: 55
title: "报表引擎 (Report Engine)"
targets:
  backend: true
  frontend: true
depends_on: [54]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V063__create_rpt_report_def.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/RptReportDef.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/mapper/RptReportDefMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/RptReportDefMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/RptReportDefAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/RptReportExecuteService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/RptReportController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/report/ReportDefQueryDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/report/ReportDefCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/report/ReportDefUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/report/ReportExecuteDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/report/ReportDefVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/report/ReportResultVO.java"
  - "ljwx-platform-admin/src/api/report/report-def.ts"
  - "ljwx-platform-admin/src/views/report/designer/index.vue"
  - "ljwx-platform-admin/src/views/report/preview/index.vue"
---
# Phase 55 — 报表引擎 (Report Engine)

| 项目 | 值 |
|-----|---|
| Phase | 55 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L5-D03 报表引擎 |
| 前置依赖 | Phase 54 (自定义表单) |
| 测试契约 | `spec/tests/phase-55-report-engine.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §JSONB 字段规范
- `spec/03-api.md` — §REST 规范
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`
- `docs/reference/list.md` — §L5-D03 报表引擎

## 功能概述

**问题**：运营人员需要对平台数据进行灵活查询和报表展示，每次新增查询需求都需要开发人员介入，效率低下。

**解决方案**：实现 SQL 模板驱动的报表引擎，支持：
1. **报表定义管理**：在线配置 SQL 查询模板、列定义、过滤器
2. **安全参数化执行**：所有 SQL 使用 `#{}` 占位符，后端安全替换，防止 SQL 注入
3. **数据源抽象**：支持 SQL 类型（直接查询 DB）和 API 类型（调用内部 API）
4. **权限隔离**：TenantLineInterceptor 自动注入 tenant_id 过滤，报表结果严格隔离

## 数据库契约

### 表结构：rpt_report_def（报表定义）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID |
| report_name | VARCHAR(100) | NOT NULL | 报表名称 |
| report_key | VARCHAR(100) | NOT NULL | 报表唯一标识 |
| data_source_type | VARCHAR(20) | NOT NULL, DEFAULT 'SQL' | 数据源类型：SQL / API |
| query_template | TEXT | NOT NULL | SQL 查询模板（使用 #{paramName} 占位符） |
| column_def | JSONB | NOT NULL | 列定义（列名、标题、类型、宽度、格式化） |
| filter_def | JSONB | NULL | 过滤器定义（参数名、类型、标签、是否必填） |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 状态：1 启用，0 停用 |
| remark | VARCHAR(500) | NULL | 备注 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**：
- `uk_report_tenant_key (tenant_id, report_key) WHERE deleted = FALSE` UNIQUE
- `idx_report_tenant_status (tenant_id, status) WHERE deleted = FALSE`

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V063__create_rpt_report_def.sql` | 建 rpt_report_def + 索引 |

**禁止**：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/reports | report:def:list | — | Result\<PageResult\<ReportDefVO\>\> | 分页列表 |
| GET | /api/v1/reports/{id} | report:def:query | — | Result\<ReportDefVO\> | 详情 |
| POST | /api/v1/reports | report:def:add | ReportDefCreateDTO | Result\<Long\> | 创建 |
| PUT | /api/v1/reports/{id} | report:def:edit | ReportDefUpdateDTO | Result\<Void\> | 更新 |
| DELETE | /api/v1/reports/{id} | report:def:delete | — | Result\<Void\> | 删除 |
| POST | /api/v1/reports/{id}/execute | report:def:execute | ReportExecuteDTO | Result\<ReportResultVO\> | 执行查询 |

## DTO / VO 契约

### ReportDefCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| reportName | String | @NotBlank, @Size(max=100) | 报表名称 |
| reportKey | String | @NotBlank, @Size(max=100), @Pattern(regexp="^[a-z][a-z0-9_]*$") | 报表唯一标识 |
| dataSourceType | String | @NotBlank, @Pattern(regexp="SQL\|API") | 数据源类型 |
| queryTemplate | String | @NotBlank | SQL 模板（仅含 #{} 参数化占位符） |
| columnDef | List | @NotNull, @Size(min=1) | 列定义列表 |
| filterDef | List | — | 过滤器定义列表 |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### ReportExecuteDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| params | Map\<String, Object\> | — | 运行时参数（对应 filter_def 中的参数） |
| pageNum | Integer | @Min(1) | 分页页码 |
| pageSize | Integer | @Min(1), @Max(1000) | 分页大小（最大 1000 行） |

### ReportDefVO

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| reportName | String | 报表名称 |
| reportKey | String | 报表标识 |
| dataSourceType | String | 数据源类型 |
| queryTemplate | String | SQL 模板 |
| columnDef | List | 列定义 |
| filterDef | List | 过滤器定义 |
| status | Integer | 状态 |
| remark | String | 备注 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

### ReportDefUpdateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| reportName | String | @NotBlank, @Size(max=100) | 报表名称 |
| dataSourceType | String | @NotBlank, @Pattern(regexp="SQL\|API") | 数据源类型 |
| queryTemplate | String | @NotBlank | SQL 模板（仅含 #{} 参数化占位符） |
| columnDef | List | @NotNull, @Size(min=1) | 列定义列表 |
| filterDef | List | — | 过滤器定义列表 |
| status | Integer | @NotNull, @Min(0), @Max(1) | 状态 |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`、`reportKey`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### ReportResultVO

| 字段 | 类型 | 说明 |
|------|------|------|
| columns | List\<ColumnMeta\> | 列元数据（name, title, type） |
| rows | List\<Map\<String, Object\>\> | 数据行 |
| total | Long | 总行数 |
| pageNum | Integer | 当前页 |
| pageSize | Integer | 每页大小 |

## 核心组件契约

### Service 类

```java
@Service
@RequiredArgsConstructor
public class RptReportDefAppService {
    // 分页查询报表定义
    public PageResult<ReportDefVO> list(ReportDefQueryDTO query);

    // 详情
    public ReportDefVO getById(Long id);

    // 创建
    @Transactional
    public Long create(ReportDefCreateDTO dto);

    // 更新
    @Transactional
    public void update(Long id, ReportDefUpdateDTO dto);

    // 删除（软删）
    @Transactional
    public void delete(Long id);
}

@Service
@RequiredArgsConstructor
public class RptReportExecuteService {
    /**
     * 执行报表查询
     * 安全要求：
     * 1. query_template 只允许 #{paramName} 占位符，禁止 ${} 直接拼接
     * 2. 禁止包含 INSERT/UPDATE/DELETE/DROP/TRUNCATE 关键字（正则校验）
     * 3. 分页大小不超过 1000 行
     * 4. 执行超时 30s
     */
    public ReportResultVO execute(Long reportId, ReportExecuteDTO dto);
}
```

### Controller 类

```java
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class RptReportController {

    @GetMapping
    @PreAuthorize("hasAuthority('report:def:list')")
    public Result<PageResult<ReportDefVO>> list(ReportDefQueryDTO query) { ... }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('report:def:query')")
    public Result<ReportDefVO> getById(@PathVariable Long id) { ... }

    @PostMapping
    @PreAuthorize("hasAuthority('report:def:add')")
    public Result<Long> create(@Valid @RequestBody ReportDefCreateDTO dto) { ... }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('report:def:edit')")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody ReportDefUpdateDTO dto) { ... }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('report:def:delete')")
    public Result<Void> delete(@PathVariable Long id) { ... }

    @PostMapping("/{id}/execute")
    @PreAuthorize("hasAuthority('report:def:execute')")
    public Result<ReportResultVO> execute(@PathVariable Long id,
                                          @Valid @RequestBody ReportExecuteDTO dto) { ... }
}
```

## 业务规则

> 格式：BL-55-{序号}：[条件] → [动作] → [结果/异常]

- **BL-55-01**：创建报表时，`report_key` 在同一租户内不可重复 → 查重后插入 → 重复时返回 409 Conflict
- **BL-55-02**：报表 SQL 模板不得包含写操作关键字（INSERT/UPDATE/DELETE/DROP/TRUNCATE/ALTER）→ 服务层正则校验 → 发现违规返回 400
- **BL-55-03**：报表 SQL 模板必须使用 `#{}` 参数化占位符，禁止 `${}` 直接拼接 → 服务层校验 → 发现 `${}` 返回 400
- **BL-55-04**：执行报表查询时，`pageSize` 最大为 1000，超出时截断 → 返回 warning 字段
- **BL-55-05**：报表执行时，TenantLineInterceptor 自动注入 tenant_id 条件，确保跨租户数据隔离
- **BL-55-06**：报表查询超时（30s）→ 中断查询 → 返回 504 带 trace_id

## 安全设计

```java
// SQL 安全校验（在 RptReportDefAppService.create/update 中调用）
private void validateQueryTemplate(String queryTemplate) {
    // 禁止写操作关键字（大小写不敏感）
    String upper = queryTemplate.toUpperCase();
    List<String> forbidden = List.of("INSERT", "UPDATE", "DELETE", "DROP", "TRUNCATE", "ALTER", "CREATE");
    for (String keyword : forbidden) {
        if (upper.contains(keyword)) {
            throw new BusinessException(400, "SQL 模板禁止包含写操作关键字: " + keyword);
        }
    }
    // 禁止 ${} 直接拼接
    if (queryTemplate.contains("${")) {
        throw new BusinessException(400, "SQL 模板禁止使用 ${} 占位符，请使用 #{}");
    }
}
```

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-55-report-engine.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-55-01 | 无 Token → 401 | P0 |
| TC-55-02 | 无 report:def:add 权限 → 403 | P0 |
| TC-55-03 | 创建报表，report_key 重复 → 409 | P0 |
| TC-55-04 | SQL 模板含 DELETE → 400 | P0 |
| TC-55-05 | SQL 模板含 ${} → 400 | P0 |
| TC-55-06 | 执行报表查询，返回正确数据 | P0 |
| TC-55-07 | 执行报表，pageSize=2000 → 截断为 1000 | P0 |
| TC-55-08 | 跨租户隔离：租户 A 执行报表只返回 A 的数据 | P0 |
| TC-55-09 | V063 无 IF NOT EXISTS，含全部审计字段 | P0 |

## 验收条件

- **AC-01**：V063 建 rpt_report_def，含 column_def/filter_def JSONB，无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`
- **AC-03**：DTO 不含禁止字段
- **AC-04**：SQL 模板写操作校验正确拦截
- **AC-05**：报表执行结果经 TenantLineInterceptor 隔离
- **AC-06**：编译通过，所有 P0 用例通过

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT，禁止在 DTO 中声明
- 权限格式：`hasAuthority('report:def:list')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · SQL 模板中的 `${}` 占位符
- DAG 依赖：core ← {security, data} ← web ← app
- 报表执行：只读 SQL，租户隔离，超时 30s，行数上限 1000
