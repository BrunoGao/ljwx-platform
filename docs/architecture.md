# LJWX Platform — 架构概览

## 系统定位

企业级多租户 SaaS 平台脚手架。支持管理后台（Admin）、移动端（uni-app Mobile）、数据大屏（Screen）三端接入。

## 后端架构

### 模块 DAG

```
ljwx-platform-core
    ↑           ↑
ljwx-platform-security   ljwx-platform-data
    ↑           ↑
ljwx-platform-web
    ↑
ljwx-platform-app   ← Spring Boot 启动入口
```

约束：
- `core` 不依赖任何其他模块
- `security` 和 `data` 仅依赖 `core`，互不依赖
- `web` 依赖 `security` 和 `data`
- `app` 是唯一的可运行模块

### 关键组件

| 组件 | 职责 |
|------|------|
| TenantLineInterceptor | MyBatis-Plus 拦截器，自动在所有 SQL 注入 `tenant_id` WHERE 条件 |
| SecurityConfig | Spring Security 配置，JWT 过滤链 |
| JwtTokenFilter | 解析 JWT，填充 SecurityContext（含 tenantId） |
| BaseEntity | 含 7 列审计字段的 MyBatis-Plus 基类 |
| Result<T> | 统一 REST 响应包装器 |

### 多租户策略

- **方式**：应用层过滤（每张业务表含 `tenant_id` 列）
- **注入点**：TenantLineInterceptor 自动读取 SecurityContext 中的 tenantId
- **禁止**：Service 层手动 `setTenantId()`；DTO/请求参数携带 tenantId

## 前端架构

```
src/
├── api/          # Axios 封装 + 各模块 API 函数
├── components/   # 全局公共组件
├── layouts/      # 布局（BasicLayout、BlankLayout）
├── router/       # Vue Router 5，手动路由定义
│   └── modules/  # 按模块拆分的路由文件
├── stores/       # Pinia 状态管理
├── views/        # 页面组件（按模块组织）
└── types/        # TypeScript 类型定义
```

### 关键约束

- 只用 `<script setup lang="ts">`，禁止 Options API
- Vue Router 5 Composition API（`useRoute()`、`useRouter()`）
- 所有 API 调用通过 `src/api/*.ts`，禁止组件内直接 fetch
- 环境变量只用 `VITE_APP_BASE_API`

## 数据库

- PostgreSQL 16
- Flyway 版本化迁移（文件命名：`V{phase}_{seq}__{description}.sql`）
- 每张业务表包含 7 列审计字段

## API 设计

- REST 风格，统一前缀 `/api/v1/`
- 响应体统一用 `Result<T>` 包装
- 认证：JWT Bearer Token
- 授权：Spring Security `@PreAuthorize("hasAuthority('resource:action')")`
- 分页：Spring `Pageable` 参数 + `PageResult<T>` 响应

## 开发环境

```bash
# 启动数据库
docker compose -f docker-compose.yml up -d

# 后端编译
mvn clean compile -f pom.xml -q

# 前端依赖安装
cd ljwx-platform-admin && pnpm install

# 前端类型检查
cd ljwx-platform-admin && pnpm run type-check
```
