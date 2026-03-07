---
phase: 11
title: "Shared Package (前端共享包)"
targets:
  backend: false
  frontend: true
depends_on: [10]
bundle_with: []
scope:
  - "packages/shared/package.json"
  - "packages/shared/tsconfig.json"
  - "packages/shared/tsup.config.ts"
  - "packages/shared/src/index.ts"
  - "packages/shared/src/types/**"
  - "packages/shared/src/constants/**"
  - "packages/shared/src/utils/**"
---
# Phase 11 — 前端共享包 (Shared Package)

| 项目 | 值 |
|-----|---|
| Phase | 11 |
| 模块 | packages/shared (前端共享 TypeScript 包) |
| Feature | F-011 (前端类型定义与常量) |
| 前置依赖 | Phase 10 (Index & Contract) |
| 测试契约 | `spec/tests/phase-11-shared.tests.yml` |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §统一响应、§错误码
- `spec/06-frontend-config.md` — §Root package.json（workspace 配置）
- `spec/01-constraints.md` — §TypeScript 约束、§RBAC 权限
- `spec/08-output-rules.md`

---

## 包结构契约

### 目录结构

```
packages/shared/
├── package.json          # 包配置，name: @ljwx/shared
├── tsconfig.json         # strict: true
├── tsup.config.ts        # 构建配置（ESM + CJS）
├── src/
│   ├── index.ts          # 统一导出
│   ├── types/
│   │   ├── index.ts      # 类型导出
│   │   ├── api.ts        # Result<T>, PageResult<T>, ErrorResponse
│   │   ├── user.ts       # UserVO, UserCreateDTO, UserUpdateDTO, UserQueryDTO
│   │   ├── role.ts       # RoleVO, RoleCreateDTO, RoleUpdateDTO, RoleQueryDTO
│   │   └── common.ts     # 通用类型（如 BaseEntity 字段类型）
│   ├── constants/
│   │   ├── index.ts      # 常量导出
│   │   ├── error-codes.ts # ErrorCode 枚举（与 spec/03-api.md 一致）
│   │   └── permissions.ts # Permission 常量（与 spec/01-constraints.md §RBAC 一致）
│   └── utils/
│       └── index.ts      # 工具函数（如有）
```

### package.json 关键字段

```json
{
  "name": "@ljwx/shared",
  "version": "1.0.0",
  "type": "module",
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    }
  },
  "scripts": {
    "build": "tsup",
    "type-check": "tsc --noEmit"
  },
  "devDependencies": {
    "tsup": "~8.5.0",
    "typescript": "~5.9.3"
  }
}
```

---

## 类型契约

### api.ts — 统一响应类型

```typescript
// 成功响应
export interface Result<T = unknown> {
  code: number
  message: string
  data: T
}

// 分页响应
export interface PageResult<T = unknown> {
  list: T[]
  total: number
}

// 错误响应
export interface ErrorResponse {
  code: number
  message: string
  timestamp: string
  path: string
}
```

### error-codes.ts — 错误码常量

与 `spec/03-api.md` §错误码表一致：

```typescript
export const ErrorCode = {
  SUCCESS: 200,
  PARAM_VALIDATION_FAILED: 400001,
  TOKEN_INVALID: 401001,
  TOKEN_EXPIRED: 401002,
  TENANT_REJECTED: 403001,
  PERMISSION_DENIED: 403002,
  RESOURCE_NOT_FOUND: 404001,
  MENU_HAS_CHILDREN: 400002,
  REPEAT_SUBMIT: 409001,
  ACCOUNT_LOCKED: 423001,
  SYSTEM_ERROR: 500001,
  // ...
} as const

export type ErrorCodeType = typeof ErrorCode[keyof typeof ErrorCode]
```

### permissions.ts — 权限常量

与 `spec/01-constraints.md` §RBAC 权限字符串一致：

```typescript
export const Permission = {
  // 用户管理
  USER_LIST: 'system:user:list',
  USER_DETAIL: 'system:user:detail',
  USER_CREATE: 'system:user:create',
  USER_UPDATE: 'system:user:update',
  USER_DELETE: 'system:user:delete',

  // 角色管理
  ROLE_LIST: 'system:role:list',
  ROLE_DETAIL: 'system:role:detail',
  ROLE_CREATE: 'system:role:create',
  ROLE_UPDATE: 'system:role:update',
  ROLE_DELETE: 'system:role:delete',

  // ... 其他权限
} as const

export type PermissionType = typeof Permission[keyof typeof Permission]
```

### user.ts / role.ts — 业务类型

```typescript
// UserVO（响应）
export interface UserVO {
  id: number
  username: string
  nickname: string
  email: string
  phone: string
  avatar: string
  status: number
  createdTime: string
  updatedTime: string
}

// UserCreateDTO（创建请求）
export interface UserCreateDTO {
  username: string
  password: string
  nickname: string
  email?: string
  phone?: string
  avatar?: string
  status?: number
}

// UserUpdateDTO（更新请求）
export interface UserUpdateDTO {
  nickname?: string
  email?: string
  phone?: string
  avatar?: string
  status?: number
}

// UserQueryDTO（查询条件）
export interface UserQueryDTO {
  username?: string
  nickname?: string
  status?: number
  page?: number
  size?: number
}
```

**禁止字段**：所有 DTO 不得包含 `tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

---

## 构建契约

### tsup.config.ts

```typescript
import { defineConfig } from 'tsup'

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['esm', 'cjs'],
  dts: true,
  clean: true,
  splitting: false,
  sourcemap: false,
  minify: false,
  treeshake: true,
})
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020"],
    "moduleResolution": "bundler",
    "strict": true,
    "declaration": true,
    "declarationMap": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

---

## 业务规则

- **BL-11-01**：所有类型定义禁止使用 `any`，必须显式声明类型
- **BL-11-02**：错误码与 `spec/03-api.md` 保持同步，新增错误码需同步更新
- **BL-11-03**：权限常量与 `spec/01-constraints.md` §RBAC 保持同步
- **BL-11-04**：DTO 类型禁止包含审计字段（tenantId / createdBy / createdTime / updatedBy / updatedTime / deleted / version）
- **BL-11-05**：构建产物同时支持 ESM 和 CJS，供不同前端项目使用

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-11-shared.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-11-01 | tsconfig strict: true 生效 | P0 |
| TC-11-02 | 无 any 类型 | P0 |
| TC-11-03 | 错误码与 spec 一致 | P0 |
| TC-11-04 | 权限常量与 spec 一致 | P0 |
| TC-11-05 | DTO 不含禁止字段 | P0 |
| TC-11-06 | 构建产物包含 ESM + CJS + .d.ts | P0 |

---

## 验收条件

- **AC-01**：tsconfig.json 设置 `strict: true`
- **AC-02**：所有类型定义无 `any`，type-check 通过
- **AC-03**：ErrorCode 常量与 `spec/03-api.md` §错误码表一致
- **AC-04**：Permission 常量与 `spec/01-constraints.md` §RBAC 权限一致
- **AC-05**：所有 DTO 不含 `tenantId` 及其他审计字段
- **AC-06**：`pnpm run build` 成功，产物包含 dist/index.js（ESM）、dist/index.cjs（CJS）、dist/index.d.ts

---

## 关键约束

- 禁止：`any` 类型 · DTO 中包含 `tenantId` 等审计字段
- TypeScript：`strict: true` 强制开启
- 版本号：devDependencies 仅用 `~`（tilde），禁止 `^`（caret）
- 构建：必须同时输出 ESM 和 CJS 格式

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
