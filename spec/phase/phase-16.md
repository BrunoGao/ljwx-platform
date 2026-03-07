---
phase: 16
title: "Mobile Feature Pages (移动端功能页面)"
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
# Phase 16 — 移动端功能页面 (Mobile Feature Pages)

| 项目 | 值 |
|-----|---|
| Phase | 16 |
| 模块 | ljwx-platform-mobile (uni-app 移动端) |
| Feature | F-016 (Mobile 功能页面) |
| 前置依赖 | Phase 15 (Mobile Scaffold) |
| 测试契约 | `spec/tests/phase-16-mobile-pages.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Mobile pages.json
- `spec/08-output-rules.md`

---

## 功能契约

### 页面清单

| 页面 | 路径 | 功能 |
|------|------|------|
| 工作台 | pages/work/index.vue | 工作台首页，展示待办事项 |
| 消息 | pages/message/index.vue | 消息列表，展示通知消息 |
| 我的 | pages/mine/index.vue | 个人中心，用户信息、设置 |

### API 文件

- `src/api/notice.ts` — 通知消息 API
- `src/api/user.ts` — 用户信息 API

---

## 验收条件

- **AC-01**：四个 tabBar 页面均有内容
- **AC-02**：无 `any` 类型
- **AC-03**：build:h5 通过（如 uni-app CLI 可用）

---

## 关键约束

- 禁止：`any` 类型
- 必须：所有 tabBar 页面有基础内容

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
