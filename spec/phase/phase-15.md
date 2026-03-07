---
phase: 15
title: "Mobile Scaffold (移动端骨架)"
targets:
  backend: false
  frontend: true
depends_on: [11]
bundle_with: [16]
scope:
  - "ljwx-platform-mobile/**"
---
# Phase 15 — 移动端骨架 (Mobile Scaffold)

| 项目 | 值 |
|-----|---|
| Phase | 15 |
| 模块 | ljwx-platform-mobile (uni-app 移动端) |
| Feature | F-015 (Mobile 基础架构) |
| 前置依赖 | Phase 11 (Shared Package) |
| 测试契约 | `spec/tests/phase-15-mobile.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Mobile package.json、§Mobile pages.json
- `spec/01-constraints.md` — §TypeScript 约束、§JWT 认证
- `spec/08-output-rules.md`

---

## 架构契约

### 技术栈

- uni-app (Vue 3)
- TypeScript ~5.9.3
- Pinia ~3.0.4

### 目录结构

```
ljwx-platform-mobile/
├── package.json
├── manifest.json
├── pages.json
├── tsconfig.json
├── .env.development
├── .env.production
├── src/
│   ├── main.ts
│   ├── App.vue
│   ├── pages/
│   │   ├── login/index.vue
│   │   ├── home/index.vue
│   │   ├── work/index.vue
│   │   ├── message/index.vue
│   │   └── mine/index.vue
│   ├── stores/
│   │   └── user.ts
│   └── api/
│       ├── request.ts
│       └── auth.ts
```

### pages.json 配置

```json
{
  "pages": [
    { "path": "pages/home/index", "style": { "navigationBarTitleText": "首页" } },
    { "path": "pages/work/index", "style": { "navigationBarTitleText": "工作台" } },
    { "path": "pages/message/index", "style": { "navigationBarTitleText": "消息" } },
    { "path": "pages/mine/index", "style": { "navigationBarTitleText": "我的" } },
    { "path": "pages/login/index", "style": { "navigationBarTitleText": "登录" } }
  ],
  "tabBar": {
    "list": [
      { "pagePath": "pages/home/index", "text": "首页", "iconPath": "static/home.png", "selectedIconPath": "static/home-active.png" },
      { "pagePath": "pages/work/index", "text": "工作台", "iconPath": "static/work.png", "selectedIconPath": "static/work-active.png" },
      { "pagePath": "pages/message/index", "text": "消息", "iconPath": "static/message.png", "selectedIconPath": "static/message-active.png" },
      { "pagePath": "pages/mine/index", "text": "我的", "iconPath": "static/mine.png", "selectedIconPath": "static/mine-active.png" }
    ]
  }
}
```

---

## 验收条件

- **AC-01**：package.json 依赖全部用 `~`，无 `^`
- **AC-02**：.env 使用 `VITE_APP_BASE_API`
- **AC-03**：登录页面可正常显示
- **AC-04**：tabBar 包含 4 个页面（首页、工作台、消息、我的）
- **AC-05**：无 `any` 类型

---

## 关键约束

- 禁止：`^` 版本前缀 · `any` 类型
- 必须：`~` 版本前缀 · `VITE_APP_BASE_API` · tabBar 4 个页面

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
