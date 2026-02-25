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
# Phase 6: AI Context Docs

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/08-output-rules.md`

## 任务

确认并微调 CLAUDE.md、spec.md（stub）、spec/INDEX.md。此时这些文件应已存在（在开始使用 Claude Code 前手动创建）。本 Phase 主要确认内容正确、无遗漏。

如果 AGENTS.md 需要创建（用于非 Claude Code 的 AI 工具），在本 Phase 生成。

## Phase-Local Manifest

```
CLAUDE.md
spec.md
spec/INDEX.md
```

## 验收条件

1. CLAUDE.md 中 Current Phase 已更新到 6
2. spec.md 是 stub，指向 CLAUDE.md 和 spec/INDEX.md
3. spec/INDEX.md 包含完整的文档索引表和防漂移规则

## 说明

本 Phase 产出量小，可与相邻 Phase Bundle。

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
