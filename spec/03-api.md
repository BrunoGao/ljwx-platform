# API 设计

## 版本与命名约定

- 认证端点固定为 `/api/auth/*`（登录/刷新/登出）。
- 业务端点统一为 `/api/v1/*`。
- 权限字符串统一为 `system:{resource}:{action}`，不使用 `ROLE_` 前缀。
- 旧版 `/api/*`（无 `v1`）路由视为历史写法，已废弃。

## 统一响应

```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "traceId": "uuid"
}
```

## 错误码（整数枚举）

| 码 | 含义 |
|-----|------|
| 200 | 成功 |
| 400001 | 参数校验失败 |
| 401001 | Token 无效 |
| 401002 | Token 过期 |
| 403001 | 租户拒绝 |
| 403002 | 权限不足 |
| 404001 | 资源不存在 |
| 500001 | 系统内部错误 |

## 路由表

### Auth

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| POST | /api/auth/login | 匿名 | 登录 |
| POST | /api/auth/refresh | 匿名 | 刷新 Token |
| POST | /api/auth/logout | 已认证 | 登出 |

### Users

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/users | system:user:list | 用户列表 |
| GET | /api/v1/users/{id} | system:user:detail | 用户详情 |
| POST | /api/v1/users | system:user:create | 创建用户 |
| PUT | /api/v1/users/{id} | system:user:update | 更新用户 |
| DELETE | /api/v1/users/{id} | system:user:delete | 删除用户 |

### Roles & Permissions

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/roles | system:role:list | 角色列表 |
| GET | /api/v1/roles/{id} | system:role:detail | 角色详情 |
| POST | /api/v1/roles | system:role:create | 创建角色 |
| PUT | /api/v1/roles/{id} | system:role:update | 更新角色 |
| DELETE | /api/v1/roles/{id} | system:role:delete | 删除角色 |
| GET | /api/v1/permissions | system:role:list | 权限列表 |

### Tenants

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/tenants | system:tenant:list | 租户列表 |
| GET | /api/v1/tenants/{id} | system:tenant:detail | 租户详情 |
| POST | /api/v1/tenants | system:tenant:create | 创建租户 |
| PUT | /api/v1/tenants/{id} | system:tenant:update | 更新租户 |
| DELETE | /api/v1/tenants/{id} | system:tenant:delete | 删除租户 |

### Jobs

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/jobs | system:job:list | 任务列表 |
| GET | /api/v1/jobs/{id} | system:job:detail | 任务详情 |
| POST | /api/v1/jobs | system:job:create | 创建任务 |
| PUT | /api/v1/jobs/{id} | system:job:update | 更新任务 |
| DELETE | /api/v1/jobs/{id} | system:job:delete | 删除任务 |
| POST | /api/v1/jobs/{id}/run | system:job:run | 立即执行 |
| POST | /api/v1/jobs/{id}/pause | system:job:pause | 暂停 |
| POST | /api/v1/jobs/{id}/resume | system:job:resume | 恢复 |

### Dicts

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/dicts/types | system:dict:list | 字典类型列表 |
| GET | /api/v1/dicts/types/{id} | system:dict:detail | 字典类型详情 |
| POST | /api/v1/dicts/types | system:dict:create | 创建字典类型 |
| PUT | /api/v1/dicts/types/{id} | system:dict:update | 更新字典类型 |
| DELETE | /api/v1/dicts/types/{id} | system:dict:delete | 删除字典类型 |
| GET | /api/v1/dicts/data/{dictType} | system:dict:list | 按类型查字典数据 |
| POST | /api/v1/dicts/data | system:dict:create | 创建字典数据 |
| PUT | /api/v1/dicts/data/{id} | system:dict:update | 更新字典数据 |
| DELETE | /api/v1/dicts/data/{id} | system:dict:delete | 删除字典数据 |

### Configs

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/configs | system:config:list | 配置列表 |
| GET | /api/v1/configs/{id} | system:config:detail | 配置详情 |
| GET | /api/v1/configs/key/{configKey} | system:config:detail | 按 key 查配置 |
| POST | /api/v1/configs | system:config:create | 创建配置 |
| PUT | /api/v1/configs/{id} | system:config:update | 更新配置 |
| DELETE | /api/v1/configs/{id} | system:config:delete | 删除配置 |
| POST | /api/v1/configs/refresh | system:config:refresh | 刷新缓存 |

### Logs

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/logs/operation | system:log:list | 操作日志列表 |
| GET | /api/v1/logs/operation/{id} | system:log:detail | 操作日志详情 |
| DELETE | /api/v1/logs/operation/{id} | system:log:delete | 删除操作日志 |
| DELETE | /api/v1/logs/operation/clean | system:log:clean | 清空操作日志 |
| GET | /api/v1/logs/login | system:log:list | 登录日志列表 |

### Files

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| POST | /api/v1/files/upload | system:file:upload | 上传文件 |
| GET | /api/v1/files/{id}/download | system:file:download | 下载文件 |
| GET | /api/v1/files | system:file:list | 文件列表 |
| DELETE | /api/v1/files/{id} | system:file:delete | 删除文件 |

### Notices

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/notices | system:notice:list | 通知列表 |
| GET | /api/v1/notices/{id} | system:notice:detail | 通知详情 |
| POST | /api/v1/notices | system:notice:create | 发布通知 |
| PUT | /api/v1/notices/{id} | system:notice:update | 更新通知 |
| DELETE | /api/v1/notices/{id} | system:notice:delete | 删除通知 |

### Menus

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/menus | system:menu:list | 菜单平铺列表 |
| GET | /api/v1/menus/tree | system:menu:list | 菜单树 |
| GET | /api/v1/menus/{id} | system:menu:detail | 菜单详情 |
| POST | /api/v1/menus | system:menu:create | 创建菜单 |
| PUT | /api/v1/menus/{id} | system:menu:update | 更新菜单 |
| DELETE | /api/v1/menus/{id} | system:menu:delete | 删除菜单（软删） |

### Depts

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/depts | system:dept:list | 部门平铺列表 |
| GET | /api/v1/depts/tree | system:dept:list | 部门树 |
| GET | /api/v1/depts/{id} | system:dept:detail | 部门详情 |
| POST | /api/v1/depts | system:dept:create | 创建部门 |
| PUT | /api/v1/depts/{id} | system:dept:update | 更新部门 |
| DELETE | /api/v1/depts/{id} | system:dept:delete | 删除部门（软删） |

### Screen

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/screen/overview | system:screen:read | 大屏概览数据 |
| GET | /api/v1/screen/realtime | system:screen:read | 大屏实时数据 |
| GET | /api/v1/screen/trend | system:screen:read | 大屏趋势数据 |
