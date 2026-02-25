---
phase: 13
title: "Admin CRUD Pages"
targets:
  backend: false
  frontend: true
depends_on: [12]
bundle_with: []
scope:
  - "ljwx-platform-admin/src/api/**"
  - "ljwx-platform-admin/src/views/**"
---
# Phase 13: Admin CRUD Pages

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — 全部路由表（Users / Roles / Tenants / Dicts / Configs / Logs / Files / Notices）
- `spec/01-constraints.md` — §TypeScript 约束
- `spec/08-output-rules.md`

## 任务

Admin 管理后台所有 CRUD 页面：用户 / 角色 / 租户 / 字典 / 配置 / 日志 / 文件 / 通知管理。

## Phase-Local Manifest

```
ljwx-platform-admin/src/api/user.ts
ljwx-platform-admin/src/api/role.ts
ljwx-platform-admin/src/api/tenant.ts
ljwx-platform-admin/src/api/dict.ts
ljwx-platform-admin/src/api/config.ts
ljwx-platform-admin/src/api/log.ts
ljwx-platform-admin/src/api/file.ts
ljwx-platform-admin/src/api/notice.ts
ljwx-platform-admin/src/api/job.ts
ljwx-platform-admin/src/views/system/user/index.vue
ljwx-platform-admin/src/views/system/role/index.vue
ljwx-platform-admin/src/views/system/tenant/index.vue
ljwx-platform-admin/src/views/system/dict/index.vue
ljwx-platform-admin/src/views/system/config/index.vue
ljwx-platform-admin/src/views/system/job/index.vue
ljwx-platform-admin/src/views/monitor/operlog/index.vue
ljwx-platform-admin/src/views/monitor/loginlog/index.vue
ljwx-platform-admin/src/views/system/file/index.vue
ljwx-platform-admin/src/views/system/notice/index.vue
```

## 验收条件

1. 每个 API 文件有完整的类型定义，无 `any`
2. 每个页面支持列表查询、新增、编辑、删除（按路由表对应的操作）
3. 所有请求路径与 spec/03-api.md 一致
4. type-check 通过

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-13-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-13-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-13-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-13-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-13-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-13-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-13-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-13-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-13-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-13-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
