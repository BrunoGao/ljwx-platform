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
