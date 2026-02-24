---
phase: 27
title: "Final Gate and Full Manifest v2"
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
# Phase 27: Final Gate & Full Manifest v2

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/` 目录全部文件（本 Phase 例外，允许全量扫描）
- `spec/08-output-rules.md`

## 任务

1. 执行 `bash scripts/gates/gate-all.sh 27` 全量校验
2. 更新 `FULL_MANIFEST.txt`（包含 Phase 20-27 新增文件）
3. 更新 `README.md`（补充新功能说明：菜单管理、部门管理、个人中心、登录日志、在线用户、系统监控、限流、WebSocket）
4. 补充 ADR 文档（如有新架构决策）
5. 最终版本验证

## 关键约束

- 本 Phase 不生成任何业务代码
- 仅更新文档和 Manifest
- 所有 gate 必须全部 PASS

## Phase-Local Manifest

```
FULL_MANIFEST.txt
README.md
```

## 验收条件

1. `bash scripts/gates/gate-all.sh 27` 全部 PASS（6/6）
2. FULL_MANIFEST.txt 包含所有新增文件
3. README.md 反映最新功能列表
