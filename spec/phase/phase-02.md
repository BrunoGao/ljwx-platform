---
phase: 2
title: "Data Module"
targets:
  backend: true
  frontend: false
depends_on: [1]
bundle_with: [3]
scope:
  - "ljwx-platform-data/**"
---
# Phase 2 — 数据访问模块 (Data Module)

| 项目 | 值 |
|-----|---|
| Phase | 2 |
| 模块 | ljwx-platform-data |
| Feature | F-002 (MyBatis 拦截器) |
| 前置依赖 | Phase 1 (Core Module) |
| 测试契约 | `spec/tests/phase-02-data.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §审计字段、§多租户行级隔离
- `spec/02-architecture.md` — §模块依赖图、§DAG 约束
- `spec/08-output-rules.md`

---

## 拦截器契约

### AuditFieldInterceptor（审计字段拦截器）

| 拦截时机 | 操作 |
|----------|------|
| INSERT | 自动填充 createdBy, createdTime, updatedBy, updatedTime |
| UPDATE | 自动填充 updatedBy, updatedTime |

数据来源：通过 `CurrentUserHolder.getCurrentUserId()` 获取当前用户 ID

### TenantLineInterceptor（租户行级拦截器）

| 拦截时机 | 操作 |
|----------|------|
| SELECT | 自动追加 `WHERE tenant_id = ?` |
| INSERT | 自动填充 tenant_id 字段 |
| UPDATE | 自动追加 `WHERE tenant_id = ?` |
| DELETE | 自动追加 `WHERE tenant_id = ?` |

数据来源：通过 `CurrentTenantHolder.getCurrentTenantId()` 获取当前租户 ID

### MyBatisConfig（配置类）

注册拦截器：
- AuditFieldInterceptor
- TenantLineInterceptor

---

## 业务规则

- **BL-02-01**：data 模块**仅依赖 core**，禁止 import `com.ljwx.platform.security.*`
- **BL-02-02**：拦截器通过 core 接口（CurrentUserHolder/CurrentTenantHolder）获取上下文，实现类由 security 模块提供
- **BL-02-03**：TenantLineInterceptor 对所有含 tenant_id 字段的表自动生效
- **BL-02-04**：审计字段由拦截器自动填充，业务代码禁止手动设置

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-02-data.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-02-01 | pom.xml 仅依赖 core，无 security | P0 |
| TC-02-02 | 全部 import 无 com.ljwx.platform.security | P0 |
| TC-02-03 | AuditFieldInterceptor 处理 INSERT 和 UPDATE | P0 |
| TC-02-04 | TenantLineInterceptor 自动追加 WHERE tenant_id | P0 |
| TC-02-05 | 编译通过 | P0 |

---

## 验收条件

- **AC-01**：`pom.xml` 依赖仅含 `ljwx-platform-core`，无 `ljwx-platform-security`
- **AC-02**：全部 import 语句无 `com.ljwx.platform.security`
- **AC-03**：AuditFieldInterceptor 处理 INSERT 和 UPDATE
- **AC-04**：TenantLineInterceptor 自动追加 `WHERE tenant_id = ?`
- **AC-05**：`./mvnw compile -pl ljwx-platform-data` 通过

---

## 关键约束

- 禁止：依赖 security 模块 · 手动设置审计字段
- DAG 约束：data 和 security 互不依赖，均只依赖 core
- 拦截器必须使用 MyBatis Interceptor 接口

## 可 Bundle

可与 Phase 3 一起执行，但分开输出。
