---
phase: 57
title: "移动端 H5 + 国际化 (Mobile H5 + i18n)"
targets:
  backend: true
  frontend: true
depends_on: [56]
bundle_with: []
scope:
  - "ljwx-platform-mobile/src/pages/login/index.vue"
  - "ljwx-platform-mobile/src/pages/home/index.vue"
  - "ljwx-platform-mobile/src/pages/todo/index.vue"
  - "ljwx-platform-mobile/src/pages/todo/detail.vue"
  - "ljwx-platform-mobile/src/pages/notice/index.vue"
  - "ljwx-platform-mobile/src/pages/profile/index.vue"
  - "ljwx-platform-mobile/src/pages/message/index.vue"
  - "ljwx-platform-mobile/src/api/auth.ts"
  - "ljwx-platform-mobile/src/api/workflow.ts"
  - "ljwx-platform-mobile/src/api/notice.ts"
  - "ljwx-platform-mobile/src/api/profile.ts"
  - "ljwx-platform-mobile/src/api/message.ts"
  - "ljwx-platform-mobile/src/store/user.ts"
  - "ljwx-platform-mobile/src/store/app.ts"
  - "ljwx-platform-mobile/src/composables/useBrand.ts"
  - "ljwx-platform-mobile/src/utils/request.ts"
  - "ljwx-platform-mobile/src/locales/zh-CN.ts"
  - "ljwx-platform-mobile/src/locales/en-US.ts"
  - "ljwx-platform-admin/src/locales/zh-CN.ts"
  - "ljwx-platform-admin/src/locales/en-US.ts"
  - "ljwx-platform-admin/src/composables/useI18n.ts"
  - "ljwx-platform-admin/src/plugins/i18n.ts"
---
# Phase 57 — 移动端 H5 + 国际化 (Mobile H5 + i18n)

| 项目 | 值 |
|-----|---|
| Phase | 57 |
| 模块 | ljwx-platform-mobile (移动端) + ljwx-platform-admin (国际化) |
| Feature | L0-D06 多端适配 + L0-D07 国际化 |
| 前置依赖 | Phase 56 (AI 助手) |
| 测试契约 | `spec/tests/phase-57-mobile-i18n.tests.yml` |
| 优先级 | 🟢 **P2** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `docs/reference/list.md` — §L0-D06 多端适配、§L0-D07 国际化
- `.claude/rules/vue-conventions.md`（自动加载）

## 功能概述

**问题**：
- 用户需要在手机端完成审批待办、查看公告、个人中心等高频场景，PC 管理后台不适合移动端操作
- 平台面向国际化客户时，需要支持中英文切换

**解决方案**：
1. **移动端 H5**（`ljwx-platform-mobile`）：基于 uni-app + Vant 实现 5 大核心移动场景
2. **Admin 国际化**（`ljwx-platform-admin`）：集成 vue-i18n，支持中英文语言包
3. **品牌适配**：移动端读取 `sys_tenant_brand` 的 `mobile` category 配置（启动图、主色调）

## 移动端 H5 六大场景

### 场景一：登录页

| 要素 | 说明 |
|------|------|
| 组件 | `pages/login/index.vue` |
| 功能 | 用户名/密码登录，验证码，登录失败提示 |
| 品牌适配 | 动态加载 `sys_tenant_brand.mobile` category 的启动图和主色调 |
| API | `POST /api/v1/auth/login` |
| Token 存储 | `uni.setStorageSync('token', ...)` |

### 场景二：首页（工作台）

| 要素 | 说明 |
|------|------|
| 组件 | `pages/home/index.vue` |
| 功能 | 待办数量角标、最近公告预览、快捷入口（待办/消息/个人中心） |
| API | `GET /api/v1/wf/tasks/todo`（count only），`GET /api/v1/notices`（最近 3 条） |

### 场景三：待办审批

| 要素 | 说明 |
|------|------|
| 组件 | `pages/todo/index.vue`（列表），`pages/todo/detail.vue`（详情+操作） |
| 功能 | 待办列表（分页），详情查看，审批同意/驳回/转办 |
| API | `GET /api/v1/wf/tasks/todo`，`POST /api/v1/wf/tasks/{id}/approve`，`POST /api/v1/wf/tasks/{id}/reject`，`POST /api/v1/wf/tasks/{id}/transfer` |
| 权限 | `system:workflow:task:list`，`system:workflow:task:approve`，`system:workflow:task:reject`，`system:workflow:task:transfer` |

### 场景四：公告列表

| 要素 | 说明 |
|------|------|
| 组件 | `pages/notice/index.vue` |
| 功能 | 公告列表（分页），点击查看详情，标记已读 |
| API | `GET /api/v1/notices`，`POST /api/v1/notices/{id}/read` |

### 场景五：个人中心

| 要素 | 说明 |
|------|------|
| 组件 | `pages/profile/index.vue` |
| 功能 | 查看个人信息，修改密码，退出登录 |
| API | `GET /api/v1/profile`，`PUT /api/v1/profile/password`，`POST /api/v1/auth/logout` |

### 场景六：消息中心

| 要素 | 说明 |
|------|------|
| 组件 | `pages/message/index.vue` |
| 功能 | 站内信列表，标记已读，全部已读 |
| API | `GET /api/v1/messages/inbox`，`POST /api/v1/messages/inbox/{id}/read` |

## 移动端技术规范

### 技术栈

| 层 | 技术 | 说明 |
|----|------|------|
| 框架 | uni-app (Vue 3) | 一套代码，编译 H5 + 小程序 |
| UI 组件 | Vant 4 | 移动端 UI 库 |
| 状态管理 | Pinia | 与 Admin 端对齐 |
| HTTP | uni.request 封装 | 复用 Token 逻辑，自动携带 X-Tenant-Id |
| 品牌 | useBrand() Composable | 读取 /api/v1/brand/config 后适配移动端主题 |

### 请求封装（utils/request.ts）

```typescript
// 自动携带 Token + Tenant ID
const request = <T>(options: UniApp.RequestOptions): Promise<T> => {
  const token = uni.getStorageSync('token')
  const tenantId = uni.getStorageSync('tenantId')
  return new Promise((resolve, reject) => {
    uni.request({
      ...options,
      header: {
        Authorization: `Bearer ${token}`,
        'X-Tenant-Id': tenantId,
        ...options.header,
      },
      success: (res) => {
        const data = res.data as ApiResult<T>
        if (data.code === 200) resolve(data.data)
        else if (data.code === 401) {
          uni.redirectTo({ url: '/pages/login/index' })
          reject(new Error('UNAUTHORIZED'))
        }
        else reject(new Error(data.message))
      },
      fail: reject,
    })
  })
}
```

### Pinia Stores（移动端）

| Store | 职责 |
|-------|------|
| useUserStore | 当前用户信息、Token、权限 Set |
| useAppStore | 应用状态（未读消息数、待办数） |

## 国际化（i18n）规范

### Admin 端集成

```typescript
// plugins/i18n.ts
import { createI18n } from 'vue-i18n'
import zhCN from '@/locales/zh-CN'
import enUS from '@/locales/en-US'

export const i18n = createI18n({
  legacy: false,           // Composition API 模式
  locale: localStorage.getItem('locale') ?? 'zh-CN',
  fallbackLocale: 'zh-CN',
  messages: { 'zh-CN': zhCN, 'en-US': enUS },
})
```

### 语言包结构（locales/zh-CN.ts）

```typescript
export default {
  common: {
    add: '新增',
    edit: '编辑',
    delete: '删除',
    search: '搜索',
    reset: '重置',
    save: '保存',
    cancel: '取消',
    confirm: '确认',
    loading: '加载中...',
    noData: '暂无数据',
  },
  menu: {
    dashboard: '仪表盘',
    user: '用户管理',
    role: '角色管理',
    // ...
  },
  // 后端错误码多语言（通过 error_code 映射）
  error: {
    '400': '请求参数错误',
    '401': '未登录或登录已过期',
    '403': '无权访问',
    '404': '资源不存在',
    '500': '服务器内部错误',
  },
}
```

### 字典多语言

> **说明**：`sys_dict_data.labels JSONB` 字段在前置 Phase（Phase 8）中已实现，本 Phase 仅使用该字段。

后端 `sys_dict_data.labels JSONB` 字段支持多语言：
```json
{ "zh": "启用", "en": "Enabled" }
```

前端读取时根据当前语言选择 label：
```typescript
const getDictLabel = (dictType: string, value: string) => {
  const locale = i18n.global.locale.value  // 'zh-CN' | 'en-US'
  const lang = locale.startsWith('zh') ? 'zh' : 'en'
  const item = dictStore.getItem(dictType, value)
  return item?.labels?.[lang] ?? item?.dictLabel ?? value
}
```

### 菜单多语言

> **说明**：`sys_menu.names JSONB` 字段在前置 Phase（Phase 4）中已实现，本 Phase 仅使用该字段。

`sys_menu.names JSONB` 字段：
```json
{ "zh": "用户管理", "en": "User Management" }
```

前端动态路由生成时使用 `names[lang]` 作为菜单标题。

### 品牌配置语言

> **说明**：`sys_tenant_brand` 表在前置 Phase（Phase 42）中已实现，本 Phase 仅新增 `platform.default_locale` 配置项。

`sys_tenant_brand` 新增条目：
- `brand_key = platform.default_locale`，`brand_value = zh-CN`，`category = basic`
- 允许租户覆盖（`allow_tenant_override = true`）

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-57-mobile-i18n.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-57-01 | 移动端登录成功，Token 存储到 uni.storage | P0 |
| TC-57-02 | Token 过期，自动跳转登录页 | P0 |
| TC-57-03 | 移动端待办列表加载，审批通过 | P0 |
| TC-57-04 | 品牌配置加载，主色调正确应用 | P0 |
| TC-57-05 | Admin 端切换语言为 en-US，菜单/按钮文字变更 | P0 |
| TC-57-06 | 字典标签根据语言动态显示 | P0 |
| TC-57-07 | 错误码 401 前端显示中文/英文错误提示 | P0 |

## 验收条件

- **AC-01**：移动端 6 大场景页面完整（登录/首页/待办审批/公告/个人中心/消息中心），含空态/加载态/错误态
- **AC-02**：移动端请求自动携带 Token + X-Tenant-Id
- **AC-03**：Admin 端支持中/英文切换，vue-i18n 集成完整
- **AC-04**：字典标签、菜单名称、错误码均支持国际化
- **AC-05**：品牌 mobile category 配置正确适配移动端主题
- **AC-06**：TypeScript 类型检查通过（pnpm run type-check）

## 关键约束（硬规则速查）

- 移动端使用 uni-app Vue 3 Composition API，禁止 Options API
- 路由使用 `uni.navigateTo/redirectTo`，不使用 vue-router
- 状态管理使用 Pinia，禁止直接修改 store 外部状态
- vue-i18n 使用 `legacy: false`（Composition API 模式）
- 语言包 key 必须使用 camelCase 路径（如 `common.add`）
- 品牌配置通过 `useBrand()` Composable 统一读取，禁止直接调用 API

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-57-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-57-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-57-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-57-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-57-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-57-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-57-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-57-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-57-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-57-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
