---
phase: 1
title: "Core Module"
targets:
  backend: true
  frontend: false
depends_on: [0]
bundle_with: [0]
scope:
  - "ljwx-platform-core/**"
---
# Phase 1 — 核心模块 (Core Module)

| 项目 | 值 |
|-----|---|
| Phase | 1 |
| 模块 | ljwx-platform-core |
| Feature | F-001 (核心基础类) |
| 前置依赖 | Phase 0 (Skeleton) |
| 测试契约 | `spec/tests/phase-01-core.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §审计字段、§多租户行级隔离
- `spec/02-architecture.md` — §模块依赖图、§Core 模块关键接口
- `spec/03-api.md` — §统一响应、§错误码
- `spec/08-output-rules.md`

---

## 类契约

### Result<T>（统一响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| code | Integer | 业务状态码（0=成功） |
| message | String | 提示信息 |
| data | T | 响应数据 |
| traceId | String | 链路追踪 ID |

静态方法：
- `Result.ok()` / `Result.ok(T data)`
- `Result.fail(ErrorCode)` / `Result.fail(int code, String message)`

### ErrorCode（错误码枚举）

| 错误码 | HTTP状态 | 说明 |
|--------|----------|------|
| SUCCESS(200) | 200 | 成功 |
| TOKEN_INVALID(401001) | 401 | Token 无效 |
| TOKEN_EXPIRED(401002) | 401 | Token 过期 |
| TENANT_REJECTED(403001) | 403 | 租户拒绝 |
| PERMISSION_DENIED(403002) | 403 | 权限不足 |
| RESOURCE_NOT_FOUND(404001) | 404 | 资源不存在 |
| PARAM_VALIDATION_FAILED(400001) | 400 | 参数校验失败 |
| MENU_HAS_CHILDREN(400002) | 400 | 菜单存在子节点，无法删除 |
| REPEAT_SUBMIT(409001) | 409 | 重复提交 |
| ACCOUNT_LOCKED(423001) | 423 | 账号锁定 |
| SYSTEM_ERROR(500001) | 500 | 系统内部错误 |

### PageResult<T>（分页响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| list | List<T> | 数据列表 |
| total | Long | 总记录数 |

### BaseEntity（审计字段基类）

| 字段 | 类型 | 注解 | 说明 |
|------|------|------|------|
| id | Long | @TableId | 主键（雪花 ID） |
| tenantId | Long | — | 租户 ID |
| createdBy | Long | — | 创建人 |
| createdTime | LocalDateTime | — | 创建时间 |
| updatedBy | Long | — | 更新人 |
| updatedTime | LocalDateTime | — | 更新时间 |
| deleted | Boolean | @TableLogic | 软删除标记 |
| version | Integer | @Version | 乐观锁版本号 |

**禁止**：业务实体重复声明这 7 个字段

### SnowflakeIdGenerator（雪花 ID 生成器）

方法：`Long nextId()`

### CurrentUserHolder（接口）

方法：`Long getCurrentUserId()`

### CurrentTenantHolder（接口）

方法：`Long getCurrentTenantId()`

---

## 业务规则

- **BL-01-01**：core 模块**零外部依赖**，仅依赖 JDK 和 Spring Boot Starter
- **BL-01-02**：CurrentUserHolder 和 CurrentTenantHolder 是接口，实现类由 security 模块提供
- **BL-01-03**：BaseEntity 的 7 个字段对应数据库审计字段，由 MyBatis Interceptor 自动填充
- **BL-01-04**：ErrorCode 枚举值必须与 spec/03-api.md 中定义的错误码一致

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-01-core.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-01-01 | pom.xml 无其他 ljwx 模块依赖 | P0 |
| TC-01-02 | Result 类包含 code/message/data/traceId | P0 |
| TC-01-03 | ErrorCode 包含所有规定的错误码 | P0 |
| TC-01-04 | BaseEntity 包含 7 个审计字段 | P0 |
| TC-01-05 | CurrentUserHolder 和 CurrentTenantHolder 是接口 | P0 |
| TC-01-06 | 编译通过 | P0 |

---

## 验收条件

- **AC-01**：`pom.xml` 无对其他 ljwx 模块的依赖
- **AC-02**：Result 类包含 code、message、data、traceId 字段
- **AC-03**：ErrorCode 枚举包含 spec/03-api.md 中定义的所有错误码
- **AC-04**：BaseEntity 包含 7 个审计字段（匹配 spec/01-constraints.md）
- **AC-05**：CurrentUserHolder 和 CurrentTenantHolder 是接口（非实现类）
- **AC-06**：`./mvnw compile -pl ljwx-platform-core` 通过

---

## 关键约束

- 禁止：依赖其他 ljwx 模块 · BaseEntity 字段在业务实体中重复声明
- core 模块是依赖树的根节点，必须保持零业务依赖
- 所有接口必须有清晰的 Javadoc 注释

## 可 Bundle

可与 Phase 0 一起执行。
