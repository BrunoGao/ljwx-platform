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

## Overview

| 项目 | 内容 |
|------|------|
| Phase | 32 |
| 模块 | 文档 / 全量校验（无业务代码） |
| Feature | Gate 全量验证、FULL_MANIFEST 更新、ADR 补充、README 更新 |
| 前置依赖 | Phase 31 |
| 测试契约 | N/A — 文档整理 Phase |

## 读取清单
- `CLAUDE.md`（自动加载）
- `spec/` 目录全部文件（本 Phase 例外，允许全量扫描）
- `spec/08-output-rules.md`

## 任务清单

1. 执行 `bash scripts/gates/gate-all.sh 32` 全量校验，确认全部 PASS（6/6）
2. 更新 `FULL_MANIFEST.txt`，补充 Phase 28–31 新增的所有文件
3. 更新 `README.md`，补充新功能说明：安全加固、可观测性、数据变更审计、前端权限指令
4. 补充 ADR 文档（见下表）
5. 更新 `CLAUDE.md` Current Phase 为 `Phase: 32 (Final Gate v3) — PASSED, ALL PHASES COMPLETE`

## ADR 清单

| 文件 | 说明 |
|------|------|
| docs/adr/006-security-hardening.md | XSS 过滤、幂等 Token、JWT 黑名单、登录锁定设计决策 |
| docs/adr/007-observability.md | TraceId 透传、结构化 JSON 日志、慢接口 AOP 监控设计决策 |
| docs/adr/008-data-change-audit.md | 字段级变更审计、@AuditChange 注解、DataChangeInterceptor 设计决策 |

> 本 Phase 为文档整理，无 HTTP 端点，验证方式：gate-all.sh 32 全部 PASS

## 关键约束

- 本 Phase 不生成任何业务代码（Controller / Service / Entity / Mapper / SQL / Vue 均禁止修改）
- 仅允许修改 FULL_MANIFEST.txt、README.md、CLAUDE.md 及新建 docs/adr/ 文件
- 所有 gate 规则（R01–R09）必须全部 PASS，退出码为 0

## 验收条件

1. `bash scripts/gates/gate-all.sh 32` 全部 PASS（6/6），退出码为 0
2. FULL_MANIFEST.txt 包含 Phase 28–31 所有新增文件
3. README.md 反映最新功能列表（安全加固、可观测性、数据变更审计、前端权限指令）
4. docs/adr/006-security-hardening.md、007-observability.md、008-data-change-audit.md 存在且内容完整

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-32-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-32-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-32-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-32-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-32-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-32-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-32-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-32-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-32-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-32-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
