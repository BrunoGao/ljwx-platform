---
phase: 32
title: "Final Gate and Full Manifest v3"
targets:
  backend: false
  frontend: false
depends_on: [31]
bundle_with: []
scope:
  - "FULL_MANIFEST.txt"
  - "docs/adr/**"
  - "README.md"
  - "CLAUDE.md"
---
# Phase 32: Final Gate & Full Manifest v3

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/` 目录全部文件（本 Phase 例外，允许全量扫描）
- `spec/08-output-rules.md`

## 任务

1. 执行 `bash scripts/gates/gate-all.sh 32` 全量校验
2. 更新 `FULL_MANIFEST.txt`（包含 Phase 28-31 新增文件）
3. 更新 `README.md`（补充新功能说明：安全加固、可观测性、数据变更审计、前端权限指令）
4. 补充 ADR 文档：
   - `docs/adr/006-security-hardening.md`（XSS/幂等/Token 黑名单/登录锁定）
   - `docs/adr/007-observability.md`（TraceId/结构化日志/慢接口监控）
   - `docs/adr/008-data-change-audit.md`（字段级变更审计设计）
5. 更新 `CLAUDE.md` Current Phase 为 `Phase: 32 (Final Gate v3) — PASSED, ALL PHASES COMPLETE`

## 关键约束

- 本 Phase 不生成任何业务代码
- 仅更新文档和 Manifest
- 所有 gate 必须全部 PASS

## Phase-Local Manifest

```
FULL_MANIFEST.txt
README.md
docs/adr/006-security-hardening.md
docs/adr/007-observability.md
docs/adr/008-data-change-audit.md
```

## 验收条件

1. `bash scripts/gates/gate-all.sh 32` 全部 PASS（6/6）
2. FULL_MANIFEST.txt 包含 Phase 28-31 所有新增文件
3. README.md 反映最新功能列表
4. 3 个新 ADR 文档存在且内容完整
