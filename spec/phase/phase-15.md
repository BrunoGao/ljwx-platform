---
phase: 15
title: "Mobile Scaffold"
targets:
  backend: false
  frontend: true
depends_on: [11]
bundle_with: [16]
scope:
  - "ljwx-platform-mobile/**"
---
# Phase 15: Mobile Scaffold

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Mobile package.json、§Mobile pages.json
- `spec/01-constraints.md` — §TypeScript 约束、§JWT 认证
- `spec/08-output-rules.md`

## 任务

uni-app 骨架：登录、首页、tabBar 配置。

## Phase-Local Manifest

```
ljwx-platform-mobile/package.json
ljwx-platform-mobile/manifest.json
ljwx-platform-mobile/pages.json
ljwx-platform-mobile/tsconfig.json
ljwx-platform-mobile/.env.development
ljwx-platform-mobile/.env.production
ljwx-platform-mobile/src/main.ts
ljwx-platform-mobile/src/App.vue
ljwx-platform-mobile/src/pages/login/index.vue
ljwx-platform-mobile/src/pages/home/index.vue
ljwx-platform-mobile/src/stores/user.ts
ljwx-platform-mobile/src/api/request.ts
ljwx-platform-mobile/src/api/auth.ts
```

## 验收条件

1. package.json 依赖全部用 `~`，无 `^`
2. .env 使用 `VITE_APP_BASE_API`
3. 登录页面可正常显示
4. tabBar 包含 4 个页面
5. 无 `any`

## 可 Bundle

可与 Phase 16 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-15-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-15-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-15-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-15-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-15-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-15-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-15-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-15-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-15-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-15-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
