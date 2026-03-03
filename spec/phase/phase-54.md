---
phase: 54
title: "自定义表单设计器 (Custom Form Designer)"
targets:
  backend: true
  frontend: true
depends_on: [53]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V061__create_form_def_and_data.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V062__create_custom_field_def.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/FormDef.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/FormData.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/CustomFieldDef.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/mapper/FormDefMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/mapper/FormDataMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/mapper/CustomFieldDefMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/FormDefMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/FormDataMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/CustomFieldDefMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/FormDefAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/FormDataAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/CustomFieldDefAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/FormDefController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/FormDataController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/CustomFieldDefController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/form/FormDefQueryDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/form/FormDefCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/form/FormDefUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/form/FormDataQueryDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/form/FormDataCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/form/FormDataUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/form/CustomFieldDefCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/form/CustomFieldDefUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/form/FormDefVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/form/FormDataVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/form/CustomFieldDefVO.java"
  - "ljwx-platform-admin/src/api/form/form-def.ts"
  - "ljwx-platform-admin/src/api/form/form-data.ts"
  - "ljwx-platform-admin/src/api/form/custom-field.ts"
  - "ljwx-platform-admin/src/views/form/designer/index.vue"
  - "ljwx-platform-admin/src/views/form/data/index.vue"
  - "ljwx-platform-admin/src/views/system/custom-field/index.vue"
---
# Phase 54 — 自定义表单设计器 (Custom Form Designer)

| 项目 | 值 |
|-----|---|
| Phase | 54 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L5-D02 自定义表单 |
| 前置依赖 | Phase 53 (流程引擎) |
| 测试契约 | `spec/tests/phase-54-custom-form.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §JSONB 字段规范
- `spec/03-api.md` — §REST 规范
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`
- `docs/reference/list.md` — §L5-D02 自定义表单

## 功能概述

**问题**：业务系统需要灵活的数据收集能力，不同租户的表单字段需求各异，硬编码表结构无法满足租户个性化需求。

**解决方案**：实现基于 JSONB 存储的自定义表单系统，支持：
1. **表单定义管理**：拖拽设计器生成 JSON Schema，存入 `sys_form_def.schema`
2. **表单数据存储**：提交数据以 JSONB 存入 `sys_form_data.field_values`
3. **自定义字段扩展**：对 `sys_user` 等核心表支持租户级自定义字段（EAV-JSONB 模式）
4. **检索策略分阶段**：MVP 仅支持固定元字段筛选，增强阶段支持 Generated Column + GIN 索引

## 数据库契约

### 表结构：sys_form_def（表单定义）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID |
| form_name | VARCHAR(100) | NOT NULL | 表单名称 |
| form_key | VARCHAR(100) | NOT NULL | 表单唯一标识 |
| schema | JSONB | NOT NULL | 字段列表、校验规则、布局（JSON Schema） |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 状态：1 启用，0 停用 |
| remark | VARCHAR(500) | NULL | 备注 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**：
- `uk_form_tenant_key (tenant_id, form_key) WHERE deleted = FALSE` UNIQUE
- `idx_form_tenant_status (tenant_id, status) WHERE deleted = FALSE`

### 表结构：sys_form_data（表单数据）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID |
| form_def_id | BIGINT | NOT NULL | 关联表单定义 ID |
| field_values | JSONB | NOT NULL | 表单字段值（JSON 对象） |
| creator_id | BIGINT | NOT NULL, DEFAULT 0 | 填写人 ID |
| creator_dept_id | BIGINT | NOT NULL, DEFAULT 0 | 填写人部门 ID |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**：
- `idx_formdata_tenant_formdef (tenant_id, form_def_id) WHERE deleted = FALSE`
- `idx_formdata_creator (tenant_id, creator_id) WHERE deleted = FALSE`
- `GIN idx_formdata_field_values (field_values jsonb_path_ops)` — 兜底全文检索

### 表结构：sys_custom_field_def（自定义字段定义）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID |
| entity_type | VARCHAR(50) | NOT NULL | 实体类型（USER/DEPT/...，大写枚举） |
| field_key | VARCHAR(100) | NOT NULL | 字段 Key（英文） |
| field_label | VARCHAR(100) | NOT NULL | 字段显示名称 |
| field_type | VARCHAR(50) | NOT NULL | 字段类型（TEXT/NUMBER/DATE/SELECT/...） |
| required | BOOLEAN | NOT NULL, DEFAULT FALSE | 是否必填 |
| sort_order | INT | NOT NULL, DEFAULT 0 | 排序 |
| options | JSONB | NULL | 可选项（下拉选项等，JSON 数组） |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**：
- `uk_customfield_tenant_entity_key (tenant_id, entity_type, field_key) WHERE deleted = FALSE` UNIQUE
- `idx_customfield_tenant_entity (tenant_id, entity_type) WHERE deleted = FALSE`

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V061__create_form_def_and_data.sql` | 建 sys_form_def + sys_form_data + 索引（含 GIN） |
| `V062__create_custom_field_def.sql` | 建 sys_custom_field_def + 索引 |

**禁止**：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

### 表单定义 API

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/form-defs | form:def:list | — | Result\<PageResult\<FormDefVO\>\> | 分页列表 |
| GET | /api/v1/form-defs/{id} | form:def:query | — | Result\<FormDefVO\> | 详情 |
| POST | /api/v1/form-defs | form:def:add | FormDefCreateDTO | Result\<Long\> | 创建 |
| PUT | /api/v1/form-defs/{id} | form:def:edit | FormDefUpdateDTO | Result\<Void\> | 更新 |
| DELETE | /api/v1/form-defs/{id} | form:def:delete | — | Result\<Void\> | 删除 |

### 表单数据 API

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/form-data | form:data:list | — | Result\<PageResult\<FormDataVO\>\> | 分页列表（元字段筛选） |
| GET | /api/v1/form-data/{id} | form:data:query | — | Result\<FormDataVO\> | 详情 |
| POST | /api/v1/form-data | form:data:add | FormDataCreateDTO | Result\<Long\> | 提交 |
| PUT | /api/v1/form-data/{id} | form:data:edit | FormDataUpdateDTO | Result\<Void\> | 更新 |

> **设计说明**：MVP 阶段表单数据不支持物理删除或软删除。原因：表单数据可能已关联流程实例，删除会破坏审计追踪。若有清理需求，通过表单定义下线（status=0）实现新数据阻止。

### 自定义字段 API

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/custom-fields | system:customfield:list | — | Result\<List\<CustomFieldDefVO\>\> | 列表（按 entityType 过滤） |
| POST | /api/v1/custom-fields | system:customfield:add | CustomFieldDefCreateDTO | Result\<Long\> | 创建 |
| PUT | /api/v1/custom-fields/{id} | system:customfield:edit | CustomFieldDefUpdateDTO | Result\<Void\> | 更新 |
| DELETE | /api/v1/custom-fields/{id} | system:customfield:delete | — | Result\<Void\> | 删除 |

## DTO / VO 契约

### FormDataQueryDTO（表单数据查询请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| formDefId | Long | @NotNull | 表单定义 ID（必填，防止全表扫描） |
| creatorId | Long | — | 填写人 ID（可选过滤） |
| startTime | LocalDateTime | — | 创建时间开始（可选，需与 endTime 同时提供） |
| endTime | LocalDateTime | — | 创建时间结束（可选，需与 startTime 同时提供，且 endTime >= startTime，最大跨度 90 天） |
| pageNum | Integer | @Min(1) | 分页页码 |
| pageSize | Integer | @Min(1), @Max(100) | 分页大小 |

**禁止字段**：`tenantId`（由 TenantLineInterceptor 自动注入）

> `formDefId` 为必填，保证查询走 `idx_formdata_tenant_formdef` 索引，符合 BL-54-06（禁止全表 JSONB 扫描）。日期区间校验在 Service 层执行。

### FormDefCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| formName | String | @NotBlank, @Size(max=100) | 表单名称 |
| formKey | String | @NotBlank, @Size(max=100), @Pattern(regexp="^[a-z][a-z0-9_]*$") | 表单唯一标识（小写字母+数字+下划线） |
| schema | Object | @NotNull | 表单 JSON Schema（字段列表+校验规则+布局） |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### FormDefUpdateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| formName | String | @NotBlank, @Size(max=100) | 表单名称 |
| schema | Object | @NotNull | 更新后的 JSON Schema |
| status | Integer | @NotNull, @Min(0), @Max(1) | 状态 |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`、`formKey`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### FormDataCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| formDefId | Long | @NotNull | 表单定义 ID |
| fieldValues | Map\<String, Object\> | @NotNull | 字段值（key=fieldKey, value=值） |

**禁止字段**：`id`、`tenantId`、`creatorId`、`creatorDeptId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### FormDataUpdateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| fieldValues | Map\<String, Object\> | @NotNull | 更新后的字段值（全量替换） |

**禁止字段**：`id`、`tenantId`、`formDefId`、`creatorId`、`creatorDeptId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### CustomFieldDefCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| entityType | String | @NotBlank, @Size(max=50), @Pattern(regexp="USER|DEPT") | 实体类型（大写枚举：USER/DEPT） |
| fieldKey | String | @NotBlank, @Size(max=100), @Pattern(regexp="^[a-z][a-z0-9_]*$") | 字段唯一标识（小写字母+数字+下划线） |
| fieldLabel | String | @NotBlank, @Size(max=100) | 显示名称 |
| fieldType | String | @NotBlank, @Pattern(regexp="TEXT\|NUMBER\|DATE\|SELECT\|CHECKBOX") | 字段类型 |
| required | Boolean | @NotNull | 是否必填 |
| sortOrder | Integer | @Min(0) | 排序 |
| options | List | — | 可选项（SELECT/CHECKBOX 类型时有效） |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### CustomFieldDefUpdateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| fieldLabel | String | @NotBlank, @Size(max=100) | 显示名称 |
| required | Boolean | @NotNull | 是否必填 |
| sortOrder | Integer | @Min(0) | 排序 |
| options | List | — | 可选项（SELECT/CHECKBOX 类型时有效） |

**禁止字段**：`id`、`entityType`、`fieldKey`、`fieldType`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

> `entityType`、`fieldKey`、`fieldType` 一旦创建不可修改（变更需删除重建，避免历史数据语义错乱）。

### FormDefVO

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| formName | String | 表单名称 |
| formKey | String | 表单标识 |
| schema | Object | JSON Schema（字段列表+布局） |
| status | Integer | 状态 |
| remark | String | 备注 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

### FormDataVO

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| formDefId | Long | 表单定义 ID |
| fieldValues | Map\<String, Object\> | 字段值 |
| creatorId | Long | 填写人 ID |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

### CustomFieldDefVO

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| entityType | String | 实体类型 |
| fieldKey | String | 字段 Key |
| fieldLabel | String | 显示名称 |
| fieldType | String | 字段类型 |
| required | Boolean | 是否必填 |
| sortOrder | Integer | 排序 |
| options | List | 可选项 |
| createdTime | LocalDateTime | 创建时间 |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

## 核心组件契约

### Service 类

```java
@Service
@RequiredArgsConstructor
public class FormDefAppService {
    // 分页查询表单定义
    public PageResult<FormDefVO> list(FormDefQueryDTO query);

    // 详情
    public FormDefVO getById(Long id);

    // 创建
    @Transactional
    public Long create(FormDefCreateDTO dto);

    // 更新
    @Transactional
    public void update(Long id, FormDefUpdateDTO dto);

    // 删除（软删）
    @Transactional
    public void delete(Long id);
}

@Service
@RequiredArgsConstructor
public class FormDataAppService {
    // 分页查询（仅元字段筛选：formDefId、creatorId、created_time 范围）
    public PageResult<FormDataVO> list(FormDataQueryDTO query);

    // 详情
    public FormDataVO getById(Long id);

    // 创建（服务层从 SecurityContext 注入 creatorId + creatorDeptId）
    @Transactional
    public Long create(FormDataCreateDTO dto);

    // 更新
    @Transactional
    public void update(Long id, FormDataUpdateDTO dto);
}

@Service
@RequiredArgsConstructor
public class CustomFieldDefAppService {
    // 列表查询（按 entityType 过滤）
    public List<CustomFieldDefVO> listByEntityType(String entityType);

    // 创建
    @Transactional
    public Long create(CustomFieldDefCreateDTO dto);

    // 更新
    @Transactional
    public void update(Long id, CustomFieldDefUpdateDTO dto);

    // 删除（软删）
    @Transactional
    public void delete(Long id);
}
```

### Controller 类

```java
@RestController
@RequestMapping("/api/v1/form-defs")
@RequiredArgsConstructor
public class FormDefController {

    @GetMapping
    @PreAuthorize("hasAuthority('form:def:list')")
    public Result<PageResult<FormDefVO>> list(FormDefQueryDTO query) { ... }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('form:def:query')")
    public Result<FormDefVO> getById(@PathVariable Long id) { ... }

    @PostMapping
    @PreAuthorize("hasAuthority('form:def:add')")
    public Result<Long> create(@Valid @RequestBody FormDefCreateDTO dto) { ... }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('form:def:edit')")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody FormDefUpdateDTO dto) { ... }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('form:def:delete')")
    public Result<Void> delete(@PathVariable Long id) { ... }
}
```

## 业务规则

> 格式：BL-54-{序号}：[条件] → [动作] → [结果/异常]

- **BL-54-01**：创建表单定义时，`form_key` 在同一租户内不可重复 → 查重后插入 → 重复时返回 409 Conflict
- **BL-54-02**：提交表单数据时，`form_def_id` 对应的表单定义必须存在且状态为启用 → 校验后存储 → 不存在或停用返回 400
- **BL-54-03**：表单数据提交时，`creatorId` 和 `creatorDeptId` 强制从 `SecurityContext` 注入 → DTO 中不允许传入 → 服务层覆盖
- **BL-54-04**：自定义字段 `field_key` 在同一租户+同一 `entity_type` 内不可重复 → 查重后插入 → 重复时返回 409
- **BL-54-05**：删除表单定义前，若存在关联的 `sys_form_data` 记录 → 拒绝删除 → 返回 400 "表单存在数据，无法删除"
- **BL-54-06**：MVP 阶段表单数据查询仅支持元字段筛选（`form_def_id`、`creator_id`、`created_time` 范围、`deleted=false`），禁止全表 JSONB 扫描

## 检索策略

| 阶段 | 检索方式 | 实现 |
|------|----------|------|
| MVP | 仅固定元字段筛选 | `WHERE form_def_id=? AND creator_id=? AND created_time BETWEEN ?` |
| 增强（Phase 54+） | 高频字段 Generated Column + 表达式索引 | 表单设计器标记"可检索"字段，后端自动执行 `ALTER TABLE ADD COLUMN ... GENERATED ALWAYS AS (field_values->>'field_key') STORED` |
| 兜底 | GIN(field_values jsonb_path_ops) | `WHERE field_values @> '{"key": "value"}'` |

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-54-custom-form.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-54-01 | 无 Token → 401 | P0 |
| TC-54-02 | 无 form:def:add 权限 → 403 | P0 |
| TC-54-03 | 创建表单定义，form_key 重复 → 409 | P0 |
| TC-54-04 | 创建表单定义成功，schema JSONB 正确存储 | P0 |
| TC-54-05 | 提交表单数据，formDefId 不存在 → 400 | P0 |
| TC-54-06 | 提交表单数据成功，field_values JSONB 正确存储 | P0 |
| TC-54-07 | 表单数据查询，按 formDefId + created_time 筛选 | P0 |
| TC-54-08 | 跨租户隔离：租户 A 无法查询租户 B 的表单数据 | P0 |
| TC-54-09 | 自定义字段 fieldKey 重复 → 409 | P0 |
| TC-54-10 | V061/V062 无 IF NOT EXISTS，含全部审计字段 | P0 |

## 验收条件

- **AC-01**：V061 建 sys_form_def（含 schema JSONB） + sys_form_data（含 field_values JSONB + GIN 索引），无 `IF NOT EXISTS`
- **AC-02**：V062 建 sys_custom_field_def，无 `IF NOT EXISTS`
- **AC-03**：所有 Controller 方法有 `@PreAuthorize`
- **AC-04**：DTO 不含禁止字段（tenantId、createdBy 等）
- **AC-05**：提交表单数据时，creatorId/creatorDeptId 从 SecurityContext 注入
- **AC-06**：编译通过，所有 P0 用例通过

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT，禁止在 DTO 中声明
- 权限格式：`hasAuthority('form:def:list')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · 在 DTO 中声明禁止字段
- DAG 依赖：core ← {security, data} ← web ← app
- JSONB 必须用 `jsonb_path_ops` 操作符类创建 GIN 索引
- MVP 阶段禁止全表 JSONB 扫描（需通过元字段索引先过滤）
