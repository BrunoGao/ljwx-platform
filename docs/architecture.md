# 架构

> 版本号以 `CLAUDE.md` 的「版本锁定」为准。

## 仓库结构（实施现状）

```text
ljwx-platform/
├── CLAUDE.md
├── spec.md
├── spec/
├── .claude/
├── .github/
├── pom.xml
├── .mvn/wrapper/
├── package.json
├── pnpm-workspace.yaml
├── .npmrc
├── .nvmrc
├── docker-compose.yml
├── .env.example
├── README.md
├── PHASE_MANIFEST.txt
├── FULL_MANIFEST.txt
│
├── ljwx-platform-core/
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/core/
│       ├── context/
│       ├── entity/
│       ├── id/
│       └── result/
│
├── ljwx-platform-security/
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/security/
│       ├── blacklist/
│       ├── config/
│       ├── context/
│       ├── filter/
│       └── jwt/
│
├── ljwx-platform-data/
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/data/
│       ├── annotation/
│       ├── config/
│       ├── context/
│       └── interceptor/
│
├── ljwx-platform-web/
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/web/
│       ├── advice/
│       ├── annotation/
│       ├── aop/
│       ├── config/
│       ├── exception/
│       ├── filter/
│       ├── interceptor/
│       └── validator/
│
├── ljwx-platform-app/
│   ├── pom.xml
│   ├── src/main/java/com/ljwx/platform/app/
│   │   ├── appservice/
│   │   ├── config/
│   │   ├── controller/
│   │   ├── domain/
│   │   │   ├── dto/
│   │   │   ├── entity/
│   │   │   └── vo/
│   │   ├── infra/
│   │   │   ├── config/
│   │   │   ├── mapper/
│   │   │   └── quartz/
│   │   ├── websocket/
│   │   └── LjwxPlatformApplication.java
│   └── src/main/resources/
│       ├── application.yml
│       ├── db/migration/
│       └── mapper/
│
├── packages/
│   └── shared/
│       ├── package.json
│       ├── tsconfig.json
│       ├── tsup.config.ts
│       └── src/
│           ├── constants/
│           ├── types/
│           └── utils/
│
├── ljwx-platform-admin/
│   ├── package.json
│   ├── vite.config.ts
│   └── src/
│       ├── api/
│       ├── composables/
│       ├── directives/
│       ├── layouts/
│       ├── router/
│       ├── stores/
│       ├── styles/
│       └── views/
│
├── ljwx-platform-mobile/
│   ├── package.json
│   ├── manifest.json
│   ├── pages.json
│   └── src/
│       ├── api/
│       ├── pages/
│       └── stores/
│
├── ljwx-platform-screen/
│   ├── package.json
│   ├── vite.config.ts
│   └── src/
│       ├── api/
│       ├── components/
│       ├── composables/
│       ├── layouts/
│       ├── router/
│       ├── styles/
│       ├── utils/
│       └── views/
│
├── docs/
│   ├── adr/
│   ├── contracts/
│   ├── reports/
│   └── setup/
│
├── scripts/
│   ├── acceptance/
│   ├── ci/
│   ├── gates/
│   ├── github/
│   ├── hooks/
│   ├── lib/
│   ├── preflight/
│   ├── reports/
│   ├── review/
│   ├── spec/
│   └── tools/
└── prompts/
```

## 后端模块依赖图（DAG）

```text
      ┌──────────────────────┐
      │  ljwx-platform-core  │
      └─────────▲────────────┘
                │
      ┌─────────┴──────────┐
      │                    │
┌─────┴────────────┐  ┌────┴─────────────┐
│ ljwx-platform-   │  │ ljwx-platform-   │
│ security         │  │ data             │
└─────▲────────────┘  └────▲─────────────┘
      │                    │
      └─────────┬──────────┘
                │
      ┌─────────┴──────────┐
      │ ljwx-platform-web  │  (depends on security + data)
      └─────────▲──────────┘
                │
      ┌─────────┴──────────┐
      │ ljwx-platform-app  │  (depends on web + data)
      └────────────────────┘
```

## Maven 直接依赖（以各模块 `pom.xml` 为准）

| 模块 | 内部模块直接依赖 |
|------|------------------|
| `ljwx-platform-core` | 无 |
| `ljwx-platform-security` | `ljwx-platform-core` |
| `ljwx-platform-data` | `ljwx-platform-core` |
| `ljwx-platform-web` | `ljwx-platform-security`, `ljwx-platform-data` |
| `ljwx-platform-app` | `ljwx-platform-web`, `ljwx-platform-data` |

说明：
- `data` 与 `security` 仍互不依赖。
- `web` 已包含对 `data` 的直接依赖（当前实现）。
- `app` 是可运行入口，聚合 `web` 与 `data`，并承载 Flyway、Quartz、WebSocket、OpenAPI 等集成能力。

## Core 契约接口（跨模块边界）

```java
public interface CurrentUserHolder {
    Long getUserId();
    String getUsername();
}

public interface CurrentTenantHolder {
    Long getTenantId();
}
```

运行时关系：
- `data` 模块拦截器依赖上述接口（来自 `core`）。
- `security` 模块提供接口实现并接入 Spring 上下文。

## 前端架构（Workspace）

- Workspace 由 `pnpm-workspace.yaml` 管理。
- `packages/shared` 提供跨端类型、常量、工具。
- 业务前端包含 3 个应用：
  - `ljwx-platform-admin`（管理后台）
  - `ljwx-platform-mobile`（uni-app 移动端）
  - `ljwx-platform-screen`（数据大屏）

## API 分层与命名

- 认证接口：`/api/auth/*`
- 业务接口：`/api/v1/*`
- 权限命名：`system:{resource}:{action}`


## GHCR -> Harbor Sync 架构（2026-02-27）

### 目标
- CI 构建与部署解耦：GitHub Actions 只负责构建并推送到 GHCR。
- 本地 k3s 集群只从 Harbor 拉取镜像，避免公网波动影响部署稳定性。
- 保持 GitOps：部署版本仍由 deploy 仓库变更驱动（ArgoCD/Flux 监听 Git）。

### 三段分离
- CI（GitHub Actions）
  - 工作流：`.github/workflows/build-and-notify.yml`
  - 输出：GHCR 镜像 + 权威 digest + webhook 事件
- Sync（本地 sync-service）
  - 接收 webhook，落 sqlite 队列，后台 Worker 使用 `skopeo` 从 GHCR 同步到 Harbor，并校验 digest
- CD（GitOps）
  - 仅消费 Harbor 镜像（推荐不可变 `sha-<shortsha>` tag 或 digest）
  - 同步成功（VERIFIED）后再更新 deploy 仓库镜像引用

### 数据与幂等
- `webhook_events.event_id` 唯一，防重放与重复通知。
- `tasks(repository,image,digest,target_repo)` 唯一，防同一 digest 重复同步。
- Worker 状态机：`PENDING -> SYNCING -> VERIFIED`，失败分为 `FAILED_RETRYABLE` 与 `FAILED_FATAL`。

### 安全
- `Authorization: Bearer <token>`
- HMAC-SHA256 签名：`X-Sync-Timestamp` + `X-Sync-Signature`
- 时间窗校验：`WEBHOOK_MAX_SKEW_SECONDS`（默认 300 秒）

### 镜像命名
- GHCR：`ghcr.io/<owner>/<repo>/<component>:sha-<shortsha>`
- Harbor：`harbor.eu.lingjingwanxiang.cn/<project>/<component>:sha-<shortsha>`
- 同步时保留 `sha-*` 与 `branch-*` 标签，便于审计与回滚。
