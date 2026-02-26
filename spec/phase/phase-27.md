---
phase: 27
title: "Interim Gate and Full Manifest v2"
targets:
  backend: false
  frontend: false
depends_on: [26]
bundle_with: []
scope:
  - "FULL_MANIFEST.txt"
  - "docs/adr/**"
  - "README.md"
---
# Phase 27: Interim Gate & Full Manifest v2

## Overview

| 属性 | 值 |
|------|-----|
| Phase | 27 |
| 模块 | 文档 / Manifest（无业务代码） |
| Feature | 阶段性 Gate 验证 + FULL_MANIFEST.txt + README.md 更新 |
| 前置依赖 | Phase 26 |
| 测试契约 | N/A — doc-only phase |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/` 目录全部文件（本 Phase 例外，允许全量扫描）
- `spec/08-output-rules.md`

## 任务

1. 执行 `bash scripts/gates/gate-all.sh 27` 全量校验，确认 6/6 PASS
2. 更新 `FULL_MANIFEST.txt`（包含 Phase 20-27 所有新增文件路径）
3. 更新 `README.md`（补充功能说明：菜单管理、部门管理、个人中心、登录日志、在线用户、系统监控、限流、WebSocket）
4. 补充 ADR 文档（如有新架构决策，写入 `docs/adr/`）
5. 最终版本验证（确认所有 Phase 20-27 文件均已落盘）

> 本 Phase 为阶段性文档整理（非项目终态），无 HTTP 端点，验证方式：`bash scripts/gates/gate-all.sh 27` 全部 PASS

## 关键约束

- 本 Phase 不生成任何业务代码
- 仅更新文档和 Manifest
- 所有 gate 必须全部 PASS

## 验收条件

1. `bash scripts/gates/gate-all.sh 27` 全部 PASS（6/6）
2. FULL_MANIFEST.txt 包含所有新增文件
3. README.md 反映最新功能列表
