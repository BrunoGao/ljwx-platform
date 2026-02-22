# API 设计

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
| GET | /api/users | user:read | 用户列表 |
| POST | /api/users | user:write | 创建用户 |
| PUT | /api/users/{id} | user:write | 更新用户 |
| DELETE | /api/users/{id} | user:delete | 删除用户 |

### Roles & Permissions

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/roles | role:read | 角色列表 |
| POST | /api/roles | role:write | 创建角色 |
| PUT | /api/roles/{id} | role:write | 更新角色 |
| DELETE | /api/roles/{id} | role:delete | 删除角色 |
| GET | /api/permissions | role:read | 权限列表 |

### Tenants

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/tenants | tenant:read | 租户列表 |
| POST | /api/tenants | tenant:write | 创建租户 |
| PUT | /api/tenants/{id} | tenant:write | 更新租户 |

### Jobs

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/jobs | job:read | 定时任务列表 |
| POST | /api/jobs | job:write | 创建任务 |
| PUT | /api/jobs/{id} | job:write | 更新任务 |
| POST | /api/jobs/{id}/execute | job:execute | 立即执行 |
| POST | /api/jobs/{id}/pause | job:write | 暂停 |
| POST | /api/jobs/{id}/resume | job:write | 恢复 |

### Dicts

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/dicts | dict:read | 字典列表 |
| POST | /api/dicts | dict:write | 创建字典 |
| PUT | /api/dicts/{id} | dict:write | 更新字典 |
| GET | /api/dicts/type/{type} | dict:read | 按类型查字典项 |

### Configs

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/configs | config:read | 配置列表 |
| POST | /api/configs | config:write | 创建配置 |
| PUT | /api/configs/{id} | config:write | 更新配置 |
| GET | /api/configs/key/{key} | config:read | 按 key 查配置 |

### Logs

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/logs/operation | log:read | 操作日志列表 |
| GET | /api/logs/login | log:read | 登录日志列表 |
| POST | /api/logs/export | log:export | 导出日志 |

### Files

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/files | file:read | 文件列表 |
| POST | /api/files/upload | file:upload | 上传文件 |
| DELETE | /api/files/{id} | file:delete | 删除文件 |
| GET | /api/files/{id}/download | file:read | 下载文件 |

### Notices

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/notices | notice:read | 通知列表 |
| POST | /api/notices | notice:write | 发布通知 |
| PUT | /api/notices/{id} | notice:write | 更新通知 |

### Screen

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/screen/overview | screen:read | 大屏概览数据 |
| GET | /api/screen/realtime | screen:read | 大屏实时数据 |
| GET | /api/screen/trend | screen:read | 大屏趋势数据 |
