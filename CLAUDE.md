# LJWX Platform Spec 编写指南

## Current Phase

**Phase: 32 (Final Gate v3) — PASSED, ALL PHASES COMPLETE**

## 技术栈版本锁定

### Backend (Java)

| 组件 | 版本 | 说明 |
|------|------|------|
| Java | 21 | LTS 版本 |
| Spring Boot | ~3.5.11 | 主框架 |
| MyBatis-Plus | ~3.0.5 | ORM |
| PostgreSQL | 16.12 | 数据库 |
| BCrypt | (Spring Security 内置) | 密码加密 |

### Frontend (Vue)

| 组件 | 版本 | 说明 |
|------|------|------|
| Vue | ~3.5.28 | 主框架 |
| Vue Router | ~5.0.2 | 路由（v5 内置 unplugin-vue-router） |
| Pinia | ~3.0.4 | 状态管理 |
| Element Plus | ~2.13.2 | UI 组件 |
| Vite | ~7.3.1 | 构建工具 |
| TypeScript | ~5.9.3 | 类型系统 |

### 环境变量

- **VITE_APP_BASE_API**: 前端 API 基础路径（如 `/api`）

## 目录
- [核心原则](#核心原则)
- [Spec 结构规范](#spec-结构规范)
- [质量检查清单](#质量检查清单)
- [常见错误与修复](#常见错误与修复)
- [最佳实践](#最佳实践)

---

## 核心原则

### 1. SSOT (Single Source of Truth)
所有关键配置必须在 Registry 中注册:
- **权限**: `spec/registry/permissions.yml`
- **Flyway 版本**: `spec/registry/migrations.yml`
- **可观测性**: `spec/registry/observability.yml`
- **全局约束**: `spec/registry/constraints.yml`

### 2. DAG 依赖硬规则
模块依赖必须严格遵守 DAG (有向无环图):
```
core ← {security, data} ← web ← app
```

**禁止**:
- ❌ core 依赖 app
- ❌ data 依赖 security
- ❌ web 依赖 app (Filter 必须在 app 模块)

### 3. 数据库兼容性
- ✅ 使用 PostgreSQL 14+ 语法
- ❌ 禁止 MySQL 专有函数 (如 `find_in_set()`)
- ✅ 使用 PostgreSQL 数组: `ancestors @> ARRAY[...]::bigint[]`

### 4. 审计字段完整性 (audit fields)
每个表必须包含 7 个审计字段 (audit fields):
```sql
tenant_id BIGINT NOT NULL DEFAULT 0,
created_by BIGINT NOT NULL DEFAULT 0,
created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_by BIGINT NOT NULL DEFAULT 0,
updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
deleted BOOLEAN NOT NULL DEFAULT FALSE,
version INT NOT NULL DEFAULT 1
```

**禁止**: `+ 7 审计字段` 这种速记方式

---

## Spec 结构规范

### 完整 Phase Spec 模板

```markdown
---
phase: XX
title: "功能名称 (English Name)"
targets:
  backend: true
  frontend: true
depends_on: [YY]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/VXXX__description.sql"
  - "ljwx-platform-app/src/main/java/.../Entity.java"
  - "ljwx-platform-app/src/main/java/.../Mapper.java"
  - "ljwx-platform-app/src/main/java/.../AppService.java"
  - "ljwx-platform-app/src/main/java/.../Controller.java"
  - "ljwx-platform-app/src/main/java/.../dto/CreateDTO.java"
  - "ljwx-platform-app/src/main/java/.../vo/VO.java"
  - "ljwx-platform-admin/src/api/xxx.ts"
  - "ljwx-platform-admin/src/views/xxx/index.vue"
---
# Phase XX — 功能名称

| 项目 | 值 |
|-----|---|
| Phase | XX |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | LX-DXX-FXX |
| 前置依赖 | Phase YY |
| 测试契约 | `spec/tests/phase-XX-xxx.tests.yml` |
| 优先级 | 🔴 **P0** / 🟡 **P1** / 🟢 **P2** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §相关表
- `spec/03-api.md` — §相关 API
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

## 功能概述

**问题**: 描述当前系统的问题

**解决方案**: 实现 XXX 功能,支持:
1. 功能点 1
2. 功能点 2
3. 功能点 3

## 数据库契约

### 表结构：table_name

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| field1 | VARCHAR(100) | NOT NULL | 字段说明 |
| field2 | INT | NOT NULL, DEFAULT 0 | 字段说明 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_xxx` (field1, deleted) UNIQUE
- `idx_tenant_id` (tenant_id)

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `VXXX__description.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/xxx | system:xxx:list | — | Result<List<VO>> | 列表查询 |
| GET | /api/v1/xxx/{id} | system:xxx:query | — | Result<VO> | 详情查询 |
| POST | /api/v1/xxx | system:xxx:add | CreateDTO | Result<Long> | 创建 |
| PUT | /api/v1/xxx/{id} | system:xxx:edit | UpdateDTO | Result<Void> | 更新 |
| DELETE | /api/v1/xxx/{id} | system:xxx:delete | — | Result<Void> | 删除 |

## DTO / VO 契约

### CreateDTO（创建请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| field1 | String | @NotBlank, @Size(max=100) | 字段说明 |
| field2 | Integer | @NotNull, @Min(0) | 字段说明 |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### UpdateDTO（更新请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| field1 | String | @NotBlank, @Size(max=100) | 字段说明 |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### VO（响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| field1 | String | 字段说明 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

## 核心组件契约

### Service 类

```java
@Service
@RequiredArgsConstructor
public class XxxAppService {

    // 列表查询
    public PageResult<XxxVO> list(XxxQueryDTO query);

    // 详情查询
    public XxxVO getById(Long id);

    // 创建
    @Transactional
    public Long create(XxxCreateDTO dto);

    // 更新
    @Transactional
    public void update(Long id, XxxUpdateDTO dto);

    // 删除
    @Transactional
    public void delete(Long id);
}
```

### Controller 类

```java
@RestController
@RequestMapping("/api/v1/xxx")
@RequiredArgsConstructor
public class XxxController {

    @GetMapping
    @PreAuthorize("hasAuthority('system:xxx:list')")
    public Result<PageResult<XxxVO>> list(XxxQueryDTO query);

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('system:xxx:query')")
    public Result<XxxVO> getById(@PathVariable Long id);

    @PostMapping
    @PreAuthorize("hasAuthority('system:xxx:add')")
    public Result<Long> create(@Valid @RequestBody XxxCreateDTO dto);

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('system:xxx:edit')")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody XxxUpdateDTO dto);

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('system:xxx:delete')")
    public Result<Void> delete(@PathVariable Long id);
}
```

## 业务规则

> 格式：BL-XX-{序号}：[条件] → [动作] → [结果/异常]

- **BL-XX-01**：条件 → 动作 → 结果
- **BL-XX-02**：条件 → 动作 → 异常

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-XX-xxx.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-XX-01 | 无 Token → 401 | P0 |
| TC-XX-02 | 无权限 → 403 | P0 |
| TC-XX-03 | 正常 CRUD | P0 |

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`
- **AC-03**：DTO 不含禁止字段
- **AC-04**：编译通过,所有 P0 用例通过

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:xxx:list')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · 在 DTO 中声明禁止字段
- DAG 依赖：core ← {security, data} ← web ← app
```

---

## 质量检查清单

### Phase Spec 必备要素

- [ ] **YAML Frontmatter 完整**
  - phase, title, targets, depends_on, bundle_with
  - scope 列表包含所有文件路径

- [ ] **数据库契约完整**
  - 表结构展开所有列（禁止 "+ 7 审计字段"）
  - 索引定义清晰
  - Flyway 版本号正确（与 Phase 号对应）

- [ ] **API 契约完整**
  - 所有 CRUD 接口定义
  - 权限标识符正确

- [ ] **DTO/VO 契约完整**
  - 字段列表完整
  - 校验注解明确
  - 禁止字段列表清晰

- [ ] **核心组件契约**
  - Service 方法签名
  - Controller 方法签名
  - 关键类的代码示例

- [ ] **业务规则清晰**
  - BL-XX-{序号} 格式
  - 条件 → 动作 → 结果

- [ ] **测试契约引用**
  - 引用 `spec/tests/phase-XX-xxx.tests.yml`
  - P0 测试用例摘要

- [ ] **前端文件路径**
  - API 文件路径
  - Vue 组件路径

### Registry 同步检查

- [ ] **permissions.yml 更新**
  - 新增权限已注册
  - 权限命名符合规范: `resource:action`
  - action 必须是: list/query/add/edit/delete

- [ ] **migrations.yml 更新**
  - Flyway 版本号已注册
  - 版本号与 Phase 号对应
  - 表名列表完整

- [ ] **observability.yml 遵守**
  - Loki label 仅使用白名单
  - Prometheus label 避免高基数

### DAG 依赖检查

- [ ] **模块依赖正确**
  - core 不依赖 app
  - data 不依赖 security
  - web 不依赖 app
  - Filter 在 app 模块（不在 web）

### 数据库兼容性检查

- [ ] **PostgreSQL 兼容**
  - 无 MySQL 专有函数
  - 使用 PostgreSQL 数组语法
  - 使用 JSONB (不是 JSON)

---

## 常见错误与修复

### 错误 1: Flyway 版本号乱序

**错误示例**:
```yaml
- version: "038"
  phase: 38
- version: "035"  # ❌ 版本号倒退
  phase: 40
```

**修复**:
```yaml
- version: "038"
  phase: 38
- version: "040"  # ✅ 版本号递增
  phase: 40
```

### 错误 2: DAG 违规

**错误示例**:
```java
// ❌ TenantDomainFilter 在 web 模块
@Component
public class TenantDomainFilter {
    @Autowired
    private TenantDomainService service;  // service 在 app 模块
}
```

**修复**:
```java
// ✅ TenantDomainFilter 移至 app 模块
// ljwx-platform-app/.../TenantDomainFilter.java
@Component
public class TenantDomainFilter {
    @Autowired
    private TenantDomainRepository repository;  // 可以依赖 data
}
```

### 错误 3: MySQL 函数不兼容

**错误示例**:
```sql
-- ❌ MySQL 专有函数
WHERE find_in_set(#{deptId}, ancestors)
```

**修复**:
```sql
-- ✅ PostgreSQL 兼容
WHERE ancestors @> ARRAY[#{deptId}]::bigint[]
```

### 错误 4: 审计字段速记

**错误示例**:
```markdown
| field1 | VARCHAR(100) | NOT NULL | 字段 1 |
| + 7 审计字段 | | |  # ❌ 速记方式
```

**修复**:
```markdown
| field1 | VARCHAR(100) | NOT NULL | 字段 1 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |
```

### 错误 5: Long 对象比较

**错误示例**:
```java
// ❌ Long 对象用 == 比较
if (userTenantId != null && userTenantId == 0) {
```

**修复**:
```java
// ✅ 使用 equals() 或拆箱
if (userTenantId != null && userTenantId.longValue() == 0L) {
// 或
if (Long.valueOf(0).equals(userTenantId)) {
```

### 错误 6: HMAC 实现错误

**错误示例**:
```java
// ❌ 字符串拼接后哈希,不是 HMAC
String signature = SHA256(appKey + timestamp + nonce + body + secretKey);
```

**修复**:
```java
// ✅ 真正的 HMAC-SHA256
String message = appKey + "\n" + timestamp + "\n" + nonce + "\n" + bodyHash;
String signature = HMAC_SHA256(key=secretKey, data=message);
```

---

## 最佳实践

### 1. 先读 Registry,再写 Spec

在编写 Phase spec 前,先检查:
- `spec/registry/permissions.yml` - 权限是否已注册
- `spec/registry/migrations.yml` - Flyway 版本号是否可用
- `spec/registry/constraints.yml` - 全局约束是否遵守

### 2. 使用 Spec Quality Gate

每次提交前运行:
```bash
python scripts/spec-quality-gate.py
```

检查:
- 权限命名规范
- Flyway 版本唯一性
- Loki/Prometheus label 合规性

### 3. 参考已有 Phase

高质量 Phase 参考:
- Phase 33: 多级缓存（完整的架构设计）
- Phase 34: Outbox 模式（完整的组件契约）
- Phase 41: 租户生命周期（完整的业务规则）

### 4. 避免过度设计

- ❌ 不要为未来需求设计
- ❌ 不要添加"可能有用"的字段
- ✅ 只实现当前 Phase 的需求
- ✅ 保持简单和聚焦

### 5. 代码示例要可执行

所有代码示例必须:
- 语法正确
- 类型匹配
- 依赖可用
- 可以直接复制使用

### 6. 测试先行

在编写 spec 时同步编写测试用例:
- P0 用例覆盖核心流程
- P1 用例覆盖边界情况
- P2 用例覆盖异常场景

---

## Spec 评审标准

### 优秀 Spec (90+ 分)

- ✅ 所有必备要素完整
- ✅ Registry 同步更新
- ✅ DAG 依赖正确
- ✅ 数据库兼容性检查通过
- ✅ 代码示例可执行
- ✅ 测试用例完整

### 合格 Spec (70-89 分)

- ✅ 核心要素完整
- ⚠️ 部分细节缺失
- ✅ 无 CRITICAL 问题
- ⚠️ 有少量高危/中等问题

### 不合格 Spec (<70 分)

- ❌ 缺少必备要素
- ❌ 有 CRITICAL 问题
- ❌ DAG 违规
- ❌ 数据库不兼容

---

## 工具与资源

### 质量门禁工具

- `scripts/spec-quality-gate.py` - 权限/Flyway/label 检查
- `scripts/check-flyway-uniqueness.py` - Flyway 唯一性检查
- `.github/workflows/spec-quality-gate.yml` - CI 自动检查

### Registry 文件

- `spec/registry/permissions.yml` - 权限 SSOT
- `spec/registry/migrations.yml` - Flyway SSOT
- `spec/registry/observability.yml` - 可观测性配置
- `spec/registry/constraints.yml` - 全局约束

### ADR 文档

- `docs/adr/ADR-0001-multi-level-cache.md` - 多级缓存
- `docs/adr/ADR-0004-outbox-pattern.md` - Outbox 模式
- `docs/adr/ADR-0006-hmac-authentication.md` - HMAC 认证
- `docs/adr/ADR-0008-workflow-visibility.md` - 工作流可见性

---

## 总结

高质量 Spec 的核心:
1. **完整性** - 所有必备要素齐全
2. **一致性** - 与 Registry 同步
3. **正确性** - 无 DAG 违规、数据库兼容
4. **可执行性** - 代码示例可直接使用
5. **可测试性** - 测试用例完整

记住: **Spec 是代码生成的唯一输入,质量决定输出。**
