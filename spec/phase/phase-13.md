---
phase: 13
title: "Admin CRUD Pages (管理后台 CRUD 页面)"
targets:
  backend: false
  frontend: true
depends_on: [12]
bundle_with: []
scope:
  - "ljwx-platform-admin/src/api/**"
  - "ljwx-platform-admin/src/views/**"
---
# Phase 13 — 管理后台 CRUD 页面 (Admin CRUD Pages)

| 项目 | 值 |
|-----|---|
| Phase | 13 |
| 模块 | ljwx-platform-admin (Vue 3 管理后台) |
| Feature | F-013 (Admin CRUD 页面) |
| 前置依赖 | Phase 12 (Admin Scaffold) |
| 测试契约 | `spec/tests/phase-13-crud.tests.yml` |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — 全部路由表（Users / Roles / Tenants / Dicts / Configs / Logs / Files / Notices / Jobs）
- `spec/01-constraints.md` — §TypeScript 约束
- `spec/08-output-rules.md`

---

## 功能契约

### 页面清单

| 模块 | 路径 | API 文件 | 页面文件 |
|------|------|----------|----------|
| 用户管理 | /system/user | src/api/user.ts | src/views/system/user/index.vue |
| 角色管理 | /system/role | src/api/role.ts | src/views/system/role/index.vue |
| 租户管理 | /system/tenant | src/api/tenant.ts | src/views/system/tenant/index.vue |
| 字典管理 | /system/dict | src/api/dict.ts | src/views/system/dict/index.vue |
| 配置管理 | /system/config | src/api/config.ts | src/views/system/config/index.vue |
| 定时任务 | /system/job | src/api/job.ts | src/views/system/job/index.vue |
| 操作日志 | /monitor/operlog | src/api/log.ts | src/views/monitor/operlog/index.vue |
| 登录日志 | /monitor/loginlog | src/api/log.ts | src/views/monitor/loginlog/index.vue |
| 文件管理 | /system/file | src/api/file.ts | src/views/system/file/index.vue |
| 通知管理 | /system/notice | src/api/notice.ts | src/views/system/notice/index.vue |

### API 文件结构

每个 API 文件包含：

```typescript
import request from '@/api/request'
import type { Result, PageResult, UserVO, UserCreateDTO, UserUpdateDTO, UserQueryDTO } from '@ljwx/shared'

// 查询列表
export function getUsers(params?: UserQueryDTO): Promise<PageResult<UserVO>> {
  return request.get('/api/v1/users', { params })
}

// 查询详情
export function getUser(id: number): Promise<UserVO> {
  return request.get(`/api/v1/users/${id}`)
}

// 创建
export function createUser(data: UserCreateDTO): Promise<number> {
  return request.post('/api/v1/users', data)
}

// 更新
export function updateUser(id: number, data: UserUpdateDTO): Promise<void> {
  return request.put(`/api/v1/users/${id}`, data)
}

// 删除
export function deleteUser(id: number): Promise<void> {
  return request.delete(`/api/v1/users/${id}`)
}
```

### 页面组件结构

每个页面包含：

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getUsers, createUser, updateUser, deleteUser } from '@/api/user'
import type { UserVO, UserCreateDTO, UserUpdateDTO, UserQueryDTO } from '@ljwx/shared'

const loading = ref(false)
const tableData = ref<UserVO[]>([])
const total = ref(0)
const queryForm = ref<UserQueryDTO>({
  page: 1,
  size: 10,
})

// 查询列表
async function fetchList() {
  loading.value = true
  try {
    const res = await getUsers(queryForm.value)
    tableData.value = res.list
    total.value = res.total
  } finally {
    loading.value = false
  }
}

// 新增/编辑对话框
const dialogVisible = ref(false)
const dialogTitle = ref('新增')
const form = ref<UserCreateDTO | UserUpdateDTO>({})

// 提交表单
async function handleSubmit() {
  // 创建或更新逻辑
}

onMounted(() => {
  fetchList()
})
</script>

<template>
  <div class="app-container">
    <!-- 查询表单 -->
    <el-form :model="queryForm" inline>
      <el-form-item label="用户名">
        <el-input v-model="queryForm.username" placeholder="请输入用户名" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="fetchList">查询</el-button>
        <el-button @click="handleAdd">新增</el-button>
      </el-form-item>
    </el-form>

    <!-- 数据表格 -->
    <el-table :data="tableData" v-loading="loading">
      <el-table-column prop="id" label="ID" />
      <el-table-column prop="username" label="用户名" />
      <el-table-column label="操作">
        <template #default="{ row }">
          <el-button link @click="handleEdit(row)">编辑</el-button>
          <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <el-pagination
      v-model:current-page="queryForm.page"
      v-model:page-size="queryForm.size"
      :total="total"
      @current-change="fetchList"
      @size-change="fetchList"
    />

    <!-- 新增/编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle">
      <el-form :model="form">
        <!-- 表单字段 -->
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>
```

---

## 业务规则

- **BL-13-01**：所有 API 请求路径与 `spec/03-api.md` 路由表一致
- **BL-13-02**：所有类型定义从 `@ljwx/shared` 导入，禁止本地重复定义
- **BL-13-03**：所有页面支持列表查询、新增、编辑、删除（按路由表对应的操作）
- **BL-13-04**：分页参数使用 `page` 和 `size`，与后端契约一致
- **BL-13-05**：所有类型定义禁止 `any`，tsconfig 开启 `strict: true`

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-13-crud.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-13-01 | 所有 API 文件存在 | P0 |
| TC-13-02 | 所有页面文件存在 | P0 |
| TC-13-03 | API 路径与 spec 一致 | P0 |
| TC-13-04 | 类型从 @ljwx/shared 导入 | P0 |
| TC-13-05 | type-check 通过 | P0 |
| TC-13-06 | 构建成功 | P0 |

---

## 验收条件

- **AC-01**：所有 API 文件（user/role/tenant/dict/config/job/log/file/notice）存在且有完整类型定义
- **AC-02**：所有页面组件存在且支持 CRUD 操作
- **AC-03**：所有 API 请求路径与 `spec/03-api.md` 一致
- **AC-04**：所有类型从 `@ljwx/shared` 导入，无本地重复定义
- **AC-05**：`pnpm run type-check` 通过，无 `any` 类型
- **AC-06**：`pnpm run build` 成功

---

## 关键约束

- 禁止：`any` 类型 · 本地重复定义类型 · API 路径与 spec 不一致
- 必须：从 `@ljwx/shared` 导入类型 · `strict: true` · 分页参数 `page` / `size`
- 页面：支持查询、新增、编辑、删除（按路由表对应的操作）

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
