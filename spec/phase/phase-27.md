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

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-27-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-27-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-27-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-27-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-27-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-27-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-27-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-27-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-27-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-27-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
