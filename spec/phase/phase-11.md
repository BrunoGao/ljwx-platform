---
phase: 11
title: "Shared Package"
targets:
  backend: false
  frontend: true
depends_on: [10]
bundle_with: []
scope:
  - "packages/shared/**"
---
# Phase 11: Shared Package

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §统一响应、§错误码（用于类型定义）
- `spec/06-frontend-config.md` — §Root package.json（检查 workspace 配置）
- `spec/01-constraints.md` — §TypeScript 约束、§RBAC 权限（用于常量）
- `spec/08-output-rules.md`

## 任务

前端共享 TS 包 packages/shared：types（API 类型定义）、constants（错误码、权限字符串）、utils、tsup 构建。

## Phase-Local Manifest

```
packages/shared/package.json
packages/shared/tsconfig.json
packages/shared/tsup.config.ts
packages/shared/src/index.ts
packages/shared/src/types/index.ts
packages/shared/src/types/api.ts
packages/shared/src/types/user.ts
packages/shared/src/types/role.ts
packages/shared/src/types/common.ts
packages/shared/src/constants/index.ts
packages/shared/src/constants/error-codes.ts
packages/shared/src/constants/permissions.ts
packages/shared/src/utils/index.ts
```

## 验收条件

1. 无 `any` 类型
2. tsconfig `strict: true`
3. 错误码与 spec/03-api.md 一致
4. 权限常量与 spec/01-constraints.md §RBAC 一致
5. `pnpm run build:shared` 通过

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-11-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-11-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-11-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-11-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-11-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-11-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-11-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-11-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-11-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-11-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
