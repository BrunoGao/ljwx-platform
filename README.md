# LJWX Platform

企业级全栈脚手架 — Java 21 / Spring Boot 3.5 后端 + Vue 3 三端前端（Admin 管理后台 / Mobile uni-app 移动端 / Screen 数据大屏）。

## 项目简介

LJWX Platform 是一个生产就绪的多租户企业平台脚手架，提供：

- **多租户隔离**：行级隔离，`TenantLineInterceptor` 自动注入 `WHERE tenant_id = ?`
- **JWT 认证**：HS256 签名，Access Token 30 分钟，Refresh Token 7 天
- **RBAC 权限**：`resource:action` 格式权限字符串，`@PreAuthorize` 注解保护每个接口
- **审计追踪**：所有业务表自动记录 `created_by`、`updated_by`、`created_time`、`updated_time`
- **菜单管理**：动态路由菜单，支持树形结构与权限绑定
- **部门管理**：树形部门结构，数据权限（DataScope）按部门隔离
- **个人中心**：用户信息修改、密码变更
- **登录日志**：记录每次登录行为，支持分页查询
- **在线用户**：实时查看在线用户列表，支持强制下线
- **系统监控**：服务器 CPU/内存/JVM 信息实时采集
- **接口限流**：`@RateLimit` 注解，基于令牌桶算法保护高频接口
- **WebSocket**：实时通知推送，`NotificationWebSocketHandler`
- **三端前端**：管理后台（Element Plus）、移动端（uni-app）、数据大屏（ECharts）

## 快速启动

### 前置条件

| 工具 | 版本 |
|------|------|
| Java JDK | 21.0.10 |
| Maven | 3.9.9（通过 `./mvnw`） |
| Node.js | 22.22.0（`.nvmrc`） |
| pnpm | 10.30.1 |
| Docker | 任意最新版 |

### 1. 启动数据库

```bash
docker-compose up -d postgres
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env，填写 JWT_SECRET 等配置
```

### 3. 启动后端

```bash
./mvnw clean package -DskipTests
java -jar ljwx-platform-app/target/ljwx-platform-app-1.0.0-SNAPSHOT.jar
```

后端默认监听 `http://localhost:8080`。

Flyway 会自动执行 `V001`–`V028` 迁移脚本，创建所有表并插入种子数据。

默认管理员账号：`admin` / `Admin@12345`

### 4. 启动管理后台

```bash
cd ljwx-platform-admin
pnpm install
pnpm dev
```

管理后台默认访问 `http://localhost:5173`。

### 5. 启动数据大屏

```bash
cd ljwx-platform-screen
pnpm install
pnpm dev
```

数据大屏默认访问 `http://localhost:5174`。

### 6. 运行 Gate 检查

```bash
bash scripts/gates/gate-all.sh 27
```

## 技术栈

### 后端

| 层 | 技术 | 版本 |
|----|------|------|
| 语言 | Java | 21 |
| 框架 | Spring Boot | 3.5.11 |
| ORM | MyBatis-Plus | 3.0.5 |
| 数据库 | PostgreSQL | 16.12 |
| 迁移 | Flyway | 由 Spring Boot BOM 管理 |
| 调度 | Quartz | 由 spring-boot-starter-quartz 管理 |
| API 文档 | springdoc-openapi | 2.8.15 |
| 缓存 | Caffeine | 由 Spring Boot BOM 管理 |

### 前端

| 层 | 技术 | 版本 |
|----|------|------|
| 框架 | Vue | ~3.5.28 |
| 路由 | Vue Router | ~5.0.2 |
| 状态管理 | Pinia | ~3.0.4 |
| UI 组件 | Element Plus | ~2.13.2 |
| 图表 | ECharts | ~6.0.0 |
| HTTP | Axios | ~1.13.5 |
| 构建 | Vite | ~7.3.1 |
| 类型 | TypeScript | ~5.9.3 |
| 包管理 | pnpm | 10.30.1 |

## 目录结构

```
ljwx-platform/
├── CLAUDE.md                    # AI 工作流规则与版本锁定
├── PHASE_MANIFEST.txt           # Phase 完成记录
├── FULL_MANIFEST.txt            # 仓库完整文件清单
├── README.md                    # 本文件
├── pom.xml                      # Maven 父 POM
├── pnpm-workspace.yaml          # pnpm 工作区配置
├── docker-compose.yml           # 本地开发环境
│
├── ljwx-platform-core/          # 核心模块（接口 + 通用类）
├── ljwx-platform-security/      # 安全模块（JWT + Spring Security）
├── ljwx-platform-data/          # 数据模块（MyBatis 拦截器）
├── ljwx-platform-web/           # Web 模块（异常处理 + 响应包装）
├── ljwx-platform-app/           # 应用模块（Controller + Service + Flyway）
│
├── packages/
│   └── shared/                  # 前端共享 TypeScript 类型包
│
├── ljwx-platform-admin/         # Vue 3 管理后台
├── ljwx-platform-mobile/        # uni-app 移动端
├── ljwx-platform-screen/        # Vue 3 数据大屏
│
├── docs/
│   ├── adr/                     # Architecture Decision Records
│   └── contracts/               # OpenAPI JSON 合约
│
├── spec/                        # 项目规格文档
│   └── phase/                   # 各 Phase 任务说明
│
└── scripts/
    ├── gates/                   # Gate 验收脚本
    ├── hooks/                   # Claude Code Hooks
    ├── tools/                   # 工具脚本
    └── acceptance/              # 验收测试脚本
```

## 模块依赖图

```
         ┌──────────────────┐
         │   ljwx-core       │  ← 仅接口 + 通用类
         └────────▲─────────┘
                  │
         ┌────────┴─────────┐
         │                  │
┌────────┴──────┐  ┌───────┴──────────┐
│ ljwx-security │  │ ljwx-data        │
│ (JWT + Auth)  │  │ (MyBatis 拦截器)  │
└────────▲──────┘  └───────▲──────────┘
         │                  │
         └────────┬─────────┘
                  │
         ┌────────┴─────────┐
         │ ljwx-web         │  ← 异常处理 + 响应包装
         └────────▲─────────┘
                  │
         ┌────────┴─────────┐
         │ ljwx-app         │  ← 聚合：Controller + Service
         └──────────────────┘
```

## API 文档

启动后端后访问：`http://localhost:8080/swagger-ui.html`

## Quality Dashboard

- 本地预览：
  - `bash scripts/gates/gate-all.sh 20`
  - `python3 -m http.server 8080 -d docs/reports`
  - 打开 `http://localhost:8080`
- 线上地址（GitHub Pages）：
  - `https://<org>.github.io/<repo>/`
- 提交仪表盘数据（PR 模式，不直推主分支）：
  - `bash scripts/deploy-dashboard.sh 20`

## GitHub Workflow 发布到本地 k3s（极简链路）

业务仓内提供 workflow：`.github/workflows/release-to-deploy.yml`，流程为：

1. 构建并推送服务镜像到 Harbor（默认 `harbor.eu.lingjingwanxiang.cn/ljwx/ljwx-platform`），产出 `image`、`imageDigest`
2. 生成 `serviceVersion=git_sha` 与 `deploymentId=sha_short-digest_short`
3. 自动给 `ljwx-deploy` 提 PR，仅更新该服务 `release-values.yaml` 的 4 个字段：
   `image`、`deploymentId`、`serviceVersion`、`imageDigest`

硬规则校验脚本：`scripts/ci/validate-deploy-values.sh`

- 缺失 `deploymentId/serviceVersion/imageDigest` 直接失败
- 检测到 `OTEL_EXPORTER_OTLP_ENDPOINT` 变化直接失败
- 检测到除 `image/deploymentId/serviceVersion/imageDigest` 之外的字段变化直接失败
- 固定 OTLP endpoint：
  `otel-collector-opentelemetry-collector.tracing.svc.cluster.local:4317`

### 必要 Secrets

- `DEPLOY_REPO_TOKEN`：可写 `ljwx-deploy` 的 GitHub Token
- `HARBOR_USERNAME`：Harbor 用户名
- `HARBOR_PASSWORD`：Harbor 密码

### 手动触发推荐参数

- `service_name`: `ljwx-platform`
- `deploy_repo`: `BrunoGaoSZ/ljwx-deploy`
- `deploy_values_file`: `apps/ljwx-platform/overlays/prod/kustomization.yaml`
- `image_repo`: 留空时默认 `harbor.eu.lingjingwanxiang.cn/ljwx/ljwx-platform`

## 本地 k3s 验收 Workflow

提供 `.github/workflows/acceptance-local-k3s.yml`（参考 `ljwx-health`），支持在 self-hosted `k3s-local` runner 上做 5 分钟内验收：

- Argo CD Application 达到 `Synced + Healthy`
- 目标 Deployment rollout 完成，且 `DEPLOYMENT_ID` 与 release values 一致
- Prometheus active targets 中 `otel-agent-metrics` 为 `UP`

## 硬规则摘要

1. **DAG 依赖**：`core ← {security, data} ← web ← app`，security 和 data 互不依赖
2. **前端 semver**：所有依赖仅用 `~`（tilde），禁止 `^`（caret）
3. **审计字段**：所有业务表必须含 7 列审计字段，均 NOT NULL + 有 DEFAULT
4. **TypeScript**：禁止 `any`，`strict: true`
5. **权限注解**：每个 Controller 方法必须 `@PreAuthorize`（login/refresh 除外）
6. **tenant_id**：DTO 中禁止出现，由后端 Interceptor 自动注入
7. **Flyway**：禁止 `IF NOT EXISTS`

完整规则见 [CLAUDE.md](./CLAUDE.md)。

## License

Copyright (c) 2026 LJWX Platform Team. All rights reserved.
