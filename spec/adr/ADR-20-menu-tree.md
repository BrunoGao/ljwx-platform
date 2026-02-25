# ADR-20-menu-tree — 菜单树构建策略

| 字段 | 值 |
|-----|----|
| ADR ID | ADR-20-menu-tree |
| Phase | 20 |
| 状态 | Accepted |
| 创建日期 | 2026-02-25 |
| 决策者 | Claude Code |

## 背景

`GET /api/v1/menus/tree` 需要返回嵌套树结构。系统菜单数量通常在 50-200 条之间（单租户），存在两种主流实现方案。

## 决策

**采用方案：内存构建（Java 侧递归）**

从数据库一次性查出当前租户所有菜单（平铺列表），在应用层按 `parentId` 分组并递归组装 `children`，按 `sort` 排序后返回。

## 备选方案

### 方案 A：递归 SQL（已拒绝）

使用 PostgreSQL `WITH RECURSIVE` CTE 在数据库侧构建树。

**优点**
- 数据库原生支持，逻辑集中
- 理论上可处理超大层级树

**缺点**
- 递归 CTE 与 MyBatis-Plus 的 TenantLineInterceptor 配合复杂（需手动维护 tenant_id 条件）
- 对菜单这种小体量数据（<200条）属于过度设计
- 可读性差，调试困难
- 无法利用 MyBatis-Plus 的乐观锁、软删除自动过滤

### 方案 B：内存构建（已采用）

一次 `selectList`（TenantLineInterceptor 自动注入 tenant_id），在 Java 中构建树。

**优点**
- 与 MyBatis-Plus 拦截器无缝配合
- 代码直观，易测试（纯 Java 逻辑）
- 对 <200 条的菜单数据性能无差异
- 软删除、租户隔离由框架自动处理

**缺点**
- 若菜单数量超过 10000 条，内存压力增大（当前场景不适用）

## 后果

**正面**
- 实现简单，与现有 MyBatis-Plus 拦截器体系一致
- 单元测试可直接测试 Java 建树逻辑，无需数据库

**负面 / 局限**
- 不适用于菜单数量 >5000 条的极端场景（当前业务不涉及）

## 实现约束

- `MenuAppService.getMenuTree()` 必须一次 `selectList` 取全部数据，禁止多次查询
- 树形组装在 Java 层完成，禁止在 `SysMenuMapper.xml` 中写 WITH RECURSIVE
- 按 `sort` 升序排列，同层级 sort 相同时按 `id` 升序稳定排序

## 参考

- Phase Spec：`spec/phase/phase-20.md` §业务规则 BL-20-05
- 类似决策：Phase 19 部门树（同样采用内存构建）
