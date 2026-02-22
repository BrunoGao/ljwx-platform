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
