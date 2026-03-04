# LJWX Platform

企业级全栈脚手架 — Java 21 / Spring Boot 3.5 后端 + Vue 3 三端前端（Admin 管理后台 / Mobile uni-app 移动端 / Screen 数据大屏）。

## 项目简介

LJWX Platform 是一个生产就绪的多租户企业平台脚手架，提供:

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
- **安全加固**：XSS 过滤、幂等 Token、JWT 黑名单、登录锁定、强密码策略
- **可观测性**：TraceId 链路追踪、结构化 JSON 日志、慢接口监控、前端错误上报
- **数据变更审计**：字段级变更追踪，`@AuditChange` 注解自动记录 before/after 值
- **前端权限指令**：`v-permission` 指令，基于权限字符串控制元素显示
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
# 推荐：本地 PostgreSQL（macOS/Homebrew）
brew services start postgresql@16

# 首次或迁移变更后：生成 baseline（一次性）
bash scripts/generate-baseline.sh

# 日常重置：默认重建数据库并导入 baseline
bash scripts/reset-database.sh
```

如需仅重置为空库（不导入 baseline）：

```bash
bash scripts/reset-database.sh --mode empty
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env，填写 JWT_SECRET 等配置（可选设置 FLYWAY_BASELINE_VERSION）
```

### 3. 启动后端

```bash
./mvnw clean package -DskipTests
SPRING_PROFILES_ACTIVE=local java -jar ljwx-platform-app/target/ljwx-platform-app-1.0.0-SNAPSHOT.jar
```

后端默认监听 `http://localhost:8080`。

`local` profile 下 Flyway 使用 baseline 模式（默认 `V052`），仅对 baseline 之后的新迁移执行增量，减少开发阶段因历史迁移导致的失败。

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

### 6. 一键 Docker Compose（推荐端到端验收）

```bash
cp .env.compose.example .env.compose
# 必须先修改 .env.compose 里的 DB_PASSWORD 为强口令
bash scripts/local/compose-stack.sh up
bash scripts/local/compose-stack.sh smoke
```

默认端口：

- backend: `http://localhost:18080`
- admin: `http://localhost:18081`
- screen: `http://localhost:18082`

说明：`postgres/redis` 仅在 compose 内网可见，默认不暴露宿主机端口。

运行 R10 E2E 闭环：

```bash
bash scripts/local/compose-stack.sh e2e
```

停止并清理：

```bash
bash scripts/local/compose-stack.sh down
```

### 7. 一键 Docker Compose（纯交付件模式）

该模式只拉取镜像，不进行本地 `docker build`，用于验收“纯交付件部署”。

```bash
cp .env.delivery.example .env.delivery
# 必填：BACKEND_IMAGE / ADMIN_IMAGE / SCREEN_IMAGE（建议使用不可变 digest）
DEPLOY_MODE=delivery bash scripts/local/compose-stack.sh up
DEPLOY_MODE=delivery bash scripts/local/compose-stack.sh smoke
```

常用命令：

```bash
DEPLOY_MODE=delivery bash scripts/local/compose-stack.sh pull
DEPLOY_MODE=delivery bash scripts/local/compose-stack.sh e2e
DEPLOY_MODE=delivery bash scripts/local/compose-stack.sh down
```

### 8. 本地 k3s 纯交付件部署（不依赖 Argo）

```bash
cp .env.k3s.delivery.example .env.k3s.delivery
# 必填：镜像引用、数据库口令；按需设置拉取凭据
bash scripts/local/k3s-delivery.sh apply
bash scripts/local/k3s-delivery.sh status
```

- 清单位于：`deploy/k3s/artifact`
- Ingress 参考模板：`deploy/k3s/artifact/ingress.example.yaml`
- Secret 参考模板：`deploy/k3s/artifact/ljwx-platform-db.secret.example.yaml`
- `MANAGE_DB_SECRET=1` 时脚本会根据 `.env.k3s.delivery` 创建/更新 `ljwx-platform-db`
- `MANAGE_PULL_SECRET=1` 时脚本会创建镜像拉取 secret 并补丁 default service account

### 9. 运行 Gate 检查

```bash
bash scripts/gates/gate-all.sh 27
```

## 技术栈

## SSH 断线会话保活（Codex / Claude）

当你从 MacBook SSH 到本机开发时，推荐使用 `tmux` 持久会话机制，确保 SSH 断开后 `codex/claude` 进程不退出，重连后可直接恢复原会话。

快速使用：

```bash
# 启动或恢复 codex 持久会话
bash scripts/tools/agent-session.sh start codex

# 启动或恢复 claude 持久会话
bash scripts/tools/agent-session.sh start claude ljwx-agent-claude

# 查看会话
bash scripts/tools/agent-session.sh status

# 重新连接默认会话
bash scripts/tools/agent-session.sh attach
```

可选：启用 SSH 登录自动回连（默认写入 `~/.zshrc`）

```bash
bash scripts/tools/install-ssh-autoreattach.sh
```

完整说明见：`docs/ops/ssh-resilient-agent-session.md`

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
├── docker-compose.yml           # 本地开发环境（数据库占位）
├── docker-compose.stack.yml     # 源码构建 compose
├── docker-compose.delivery.yml  # 纯交付件 compose（仅镜像拉取）
├── .env.compose.example         # 源码构建 compose 环境模板
├── .env.delivery.example        # 纯交付件 compose 环境模板
├── .env.k3s.delivery.example    # k3s 纯交付件环境模板
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
├── deploy/
│   └── k3s/artifact/            # k3s 纯交付件部署清单（backend/admin/screen）
│
└── scripts/
    ├── gates/                   # Gate 验收脚本
    ├── hooks/                   # Claude Code Hooks
    ├── local/                   # 本地 compose/k3s 快速部署脚本
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

## GitHub 项目治理骨架

- 全生命周期配置文档：`docs/setup/github-config.md`
- 关键初始化脚本：
  - `bash scripts/setup-github.sh --apply --phase-range 00-53 --init-milestones`
  - `bash scripts/github/apply-branch-protection.sh --apply`
  - `bash scripts/github/setup-environments.sh --apply`
- 安全与治理工作流：
  - `dependabot` / `CodeQL` / `Dependency Review` / `Secret Scan` / `SBOM`
  - `PR Policy` / `Governance Drift`（流程准入与配置漂移检测）
  - 覆盖率工作流：`Coverage`（默认阈值：line>=40%、diff>=70%，支持可选 Codecov）

## GitHub Workflow 发布到本地 k3s（极简链路）

业务仓内提供两条 workflow，形成 `GHCR -> Harbor Pull Replication -> queue -> promoter -> Argo`：

1. `.github/workflows/build-and-notify.yml`
   - 在 GitHub-hosted runner 构建并推送 backend/admin-ui/screen 到 GHCR
   - 产出 `release-metadata` artifact（包含 backend digest/tag）
   - 通知 sync-service（由它负责 GHCR -> Harbor 同步）
2. `.github/workflows/release-to-deploy.yml`
   - 读取 `build-and-notify` 的 `release-metadata` artifact
   - 自动给 `ljwx-deploy` 提 PR，仅更新 `release/queue.yaml`（新增 pending 条目）
   - 不等待 Harbor 同步完成（异步由 deploy-promoter 处理）

### 必要 Secrets

- `DEPLOY_REPO_TOKEN`：可写 `ljwx-deploy` 的 GitHub Token
- `SYNC_WEBHOOK_URL` / `SYNC_WEBHOOK_SECRET` / `SYNC_BEARER_TOKEN`：sync-service 回调密钥（用于 GHCR -> Harbor 同步事件）
- `HARBOR_USERNAME` / `HARBOR_PASSWORD`：仅 `acceptance-local-k3s` 需要（自动注入 imagePullSecret）

### 手动触发推荐参数

- `service`: `ljwx-platform`
- `environment`: `prod`
- `deploy_repo`: `BrunoGaoSZ/ljwx-deploy`
- `queue_file`: `release/queue.yaml`

## 本地 k3s 验收 Workflow

提供 `.github/workflows/acceptance-local-k3s.yml`（参考 `ljwx-health`），支持在 self-hosted `k3s-local` runner 上做 5 分钟内验收：

- Argo CD Application 达到 `Synced + Healthy`
- 目标 Deployment rollout 完成，且 `DEPLOYMENT_ID` 与 release values 一致
- Prometheus active targets 中 `otel-agent-metrics` 为 `UP`

若只需要验证“交付件可直接落地 k3s”（不经过 Argo），可使用：

- `bash scripts/local/k3s-delivery.sh apply`
- `bash scripts/local/k3s-delivery.sh status`

## Grafana 可观测看板（日志 + 链路 + 指标）

- 统一看板文件：`k8s/grafana-dashboard-observability.json`
- 自动部署命令：
  - `bash scripts/ops/apply-grafana-observability-dashboard.sh`
- 使用说明：
  - `docs/ops/grafana-observability-dashboard.md`

## 主分支自动修复闭环（Full Test + Auto Repair）

- 监控入口：`.github/workflows/main-branch-auto-repair.yml`
- 触发条件：
  - `CI` / `Gate Check` / `Post Merge E2E` / `Nightly Regression` 在 `main|master` 失败后自动触发
  - 或手工 `workflow_dispatch` 指定失败 `run_id`
- 自动动作：
  - 收集失败 run 日志（`scripts/ci/collect-github-failures.sh`）
  - 归因分类（`closed-loop-collect -> closed-loop-diagnose`）
  - 执行修复配方（`scripts/ci/closed-loop-repair.sh` + `scripts/ci/repair-recipes.yaml`）
  - 若产生代码变更则自动提交并推送主分支，触发下一轮全量测试
- 终止策略：
  - 默认最多 `3` 次自动修复（可在手工触发时调整）
  - 超限或无可修复配方时自动创建/更新 Issue 转人工

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
