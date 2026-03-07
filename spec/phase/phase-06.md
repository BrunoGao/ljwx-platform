---
phase: 6
title: "AI Context Docs"
targets:
  backend: false
  frontend: false
depends_on: [5]
bundle_with: []
scope:
  - "CLAUDE.md"
  - "spec.md"
  - "spec/INDEX.md"
---
# Phase 6 — AI 上下文文档 (AI Context Docs)

| 项目 | 值 |
|-----|---|
| Phase | 6 |
| 模块 | 根目录文档 |
| Feature | F-006 (AI 协作文档) |
| 前置依赖 | Phase 5 (App Skeleton) |
| 测试契约 | `spec/tests/phase-06-docs.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/08-output-rules.md` — 全文

---

## 文档契约

### CLAUDE.md（主文档）

| 章节 | 必需内容 |
|------|----------|
| 工作流程 | Preflight 检查、Phase 执行流程 |
| Current Phase | 当前 Phase 编号和状态 |
| 硬规则 | 14 条硬规则（DAG、semver、审计字段等） |
| 版本锁定 | 后端/前端依赖版本表（SINGLE SOURCE OF TRUTH） |
| 代码风格参考 | Controller/Service/Vue 组件少样本 |
| 反模式 | 禁止的代码模式清单 |
| Compact 指令 | 压缩时保留的关键信息 |

**关键要求**：
- Current Phase 必须与 PHASE_MANIFEST.txt 同步
- 版本号必须与 CLAUDE.md 中的版本锁定表一致
- 硬规则编号 1-14，不可遗漏

### spec.md（Stub）

指向文档：
```markdown
# LJWX Platform Specification

本项目使用 AI-Native 开发流程。

## 主文档
- **CLAUDE.md** — Claude Code 工作指南（包含硬规则、版本锁定、工作流程）
- **spec/INDEX.md** — 详细规格索引

## 使用说明
1. 执行 Phase 前先读取 CLAUDE.md
2. 按 Phase spec 中的"读取清单"读取相关章节
3. 禁止扫描整个 spec/ 目录（Phase 19 除外）
```

### spec/INDEX.md（索引）

| 章节 | 内容 |
|------|------|
| 文档索引表 | 所有 spec/*.md 文件的用途说明 |
| 防漂移规则 | 版本号、硬规则的唯一来源声明 |
| Phase 导航 | Phase 0-32 的标题和依赖关系 |

---

## 业务规则

- **BL-06-01**：CLAUDE.md 是版本号的 SINGLE SOURCE OF TRUTH，其他文件禁止重复写版本号
- **BL-06-02**：Current Phase 必须与 PHASE_MANIFEST.txt 最后一行同步
- **BL-06-03**：spec.md 是 stub，仅指向主文档，不包含实质内容
- **BL-06-04**：spec/INDEX.md 必须包含所有 spec/*.md 文件的索引

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-06-docs.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-06-01 | CLAUDE.md 包含 14 条硬规则 | P0 |
| TC-06-02 | CLAUDE.md 包含版本锁定表 | P0 |
| TC-06-03 | CLAUDE.md Current Phase 与 PHASE_MANIFEST.txt 同步 | P0 |
| TC-06-04 | spec.md 是 stub，指向主文档 | P0 |
| TC-06-05 | spec/INDEX.md 包含文档索引表 | P0 |
| TC-06-06 | CLAUDE.md 包含工作流程章节 | P0 |

---

## 验收条件

- **AC-01**：CLAUDE.md 包含完整的 14 条硬规则
- **AC-02**：CLAUDE.md 包含版本锁定表（后端/前端）
- **AC-03**：CLAUDE.md Current Phase 与 PHASE_MANIFEST.txt 最后一行一致
- **AC-04**：spec.md 是 stub，仅指向 CLAUDE.md 和 spec/INDEX.md
- **AC-05**：spec/INDEX.md 包含所有 spec/*.md 文件的索引
- **AC-06**：CLAUDE.md 包含代码风格参考和反模式清单

---

## 关键约束

- 禁止：在 spec/*.md 中重复写版本号 · Current Phase 与 PHASE_MANIFEST.txt 不同步
- CLAUDE.md 是版本号的唯一来源（SINGLE SOURCE OF TRUTH）
- spec.md 必须保持为 stub，不包含实质内容

## 说明

本 Phase 产出量小，主要是文档完整性验证。测试用例以静态文件检查为主。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-06-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-06-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-06-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-06-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-06-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-06-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-06-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-06-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-06-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-06-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
