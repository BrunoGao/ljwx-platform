---
phase: 16
title: "Mobile Feature Pages"
targets:
  backend: false
  frontend: true
depends_on: [15]
bundle_with: [15]
scope:
  - "ljwx-platform-mobile/src/pages/**"
  - "ljwx-platform-mobile/src/api/notice.ts"
  - "ljwx-platform-mobile/src/api/user.ts"
---
# Phase 16: Mobile Feature Pages

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Mobile pages.json
- `spec/08-output-rules.md`

## 任务

移动端工作台、消息、个人中心页面。

## Phase-Local Manifest

```
ljwx-platform-mobile/src/pages/work/index.vue
ljwx-platform-mobile/src/pages/message/index.vue
ljwx-platform-mobile/src/pages/mine/index.vue
ljwx-platform-mobile/src/api/notice.ts
ljwx-platform-mobile/src/api/user.ts
```

## 验收条件

1. 四个 tabBar 页面均有内容
2. 无 `any`
3. build:h5 通过（如 uni-app CLI 可用）

## 可 Bundle

可与 Phase 15 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-16-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-16-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-16-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-16-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-16-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-16-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-16-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-16-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-16-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-16-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
