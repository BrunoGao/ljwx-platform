---
phase: 0
title: "Project Skeleton"
targets:
  backend: true
  frontend: true
depends_on: []
bundle_with: [1]
scope:
  - "pom.xml"
  - ".mvn/**"
  - "pnpm-workspace.yaml"
  - "package.json"
  - ".npmrc"
  - ".nvmrc"
  - "docker-compose.yml"
  - ".env.example"
  - ".gitignore"
  - ".editorconfig"
  - "scripts/gates/**"
  - "scripts/tools/**"
  - "scripts/acceptance/**"
  - "PHASE_MANIFEST.txt"
---
# Phase 0 — 项目骨架 (Project Skeleton)

| 项目 | 值 |
|-----|---|
| Phase | 0 |
| 模块 | 根目录配置文件 + CI 脚本 |
| Feature | F-000 (项目初始化) |
| 前置依赖 | 无 |
| 测试契约 | `spec/tests/phase-00-skeleton.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-architecture.md` — §仓库结构
- `spec/06-frontend-config.md` — §pnpm-workspace.yaml、§Root package.json、§.npmrc、§.nvmrc、§.env.example
- `spec/07-devops.md` — §Docker Compose、§CI Gate 脚本全部
- `spec/08-output-rules.md` — 全文

---

## 配置文件契约

### pom.xml（根 POM）

| 配置项 | 要求 |
|--------|------|
| groupId | com.ljwx.platform |
| artifactId | ljwx-platform |
| version | 1.0.0-SNAPSHOT |
| packaging | pom |
| parent | org.springframework.boot:spring-boot-starter-parent:3.5.11 |
| java.version | 21 |
| modules | core, security, data, web, app |

### package.json（根）

| 配置项 | 要求 |
|--------|------|
| name | ljwx-platform |
| private | true |
| packageManager | pnpm@10.30.1 |
| workspaces | ["ljwx-platform-admin", "ljwx-platform-mobile", "ljwx-platform-screen", "ljwx-platform-shared"] |

**禁止**：所有依赖版本号使用 `^`（caret），必须使用 `~`（tilde）

### pnpm-workspace.yaml

```yaml
packages:
  - 'ljwx-platform-admin'
  - 'ljwx-platform-mobile'
  - 'ljwx-platform-screen'
  - 'ljwx-platform-shared'
```

### .nvmrc

```
22.22.0
```

### .npmrc

```
shamefully-hoist=true
strict-peer-dependencies=false
```

### docker-compose.yml

| 服务 | 镜像 | 端口 | 说明 |
|------|------|------|------|
| postgres | postgres:16.12-alpine | 5432:5432 | PostgreSQL 数据库 |
| prometheus | prom/prometheus:latest | 9090:9090 | 监控（可选） |

### .env.example

```bash
# 后端
DB_URL=jdbc:postgresql://localhost:5432/ljwx_platform
DB_USERNAME=postgres
DB_PASSWORD=postgres
JWT_SECRET=your-secret-key-here

# 前端（Admin）
VITE_APP_BASE_API=http://localhost:8080
```

**禁止**：使用 `VITE_API_BASE_URL`（已废弃）

---

## CI 脚本契约

### gate-all.sh

调用所有 gate 脚本，任一失败则整体失败。

### gate-compile.sh

检查后端编译（`mvn compile`）和前端类型检查（`pnpm type-check`）。

### gate-manifest.sh

检查：
- 7 列审计字段（均非空且含默认值，字段名详见 CLAUDE.md §审计字段完整性）
- 禁止 `^` 版本号（caret）
- 禁止 `VITE_API_BASE_URL`
- 禁止 `IF NOT EXISTS` in Flyway SQL

### gate-contract.sh

检查 OpenAPI 契约一致性。

### gate-integration.sh

运行集成测试。

### gate-nfr.sh

检查非功能性需求（性能、安全）。

---

## 业务规则

- **BL-00-01**：所有前端 package.json 版本号必须使用 `~`（tilde），禁止 `^`（caret）
- **BL-00-02**：环境变量名称必须使用 `VITE_APP_BASE_API`，禁止 `VITE_API_BASE_URL`
- **BL-00-03**：PostgreSQL 镜像版本锁定为 `16.12-alpine`
- **BL-00-04**：Maven Wrapper 版本为 3.9.9

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-00-skeleton.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-00-01 | pom.xml Java 版本 = 21 | P0 |
| TC-00-02 | package.json 无 caret 版本号 | P0 |
| TC-00-03 | .nvmrc 内容 = 22.22.0 | P0 |
| TC-00-04 | docker-compose.yml 使用 postgres:16.12-alpine | P0 |
| TC-00-05 | .env.example 使用 VITE_APP_BASE_API | P0 |
| TC-00-06 | gate-manifest.sh 包含审计字段检查 | P0 |

---

## 验收条件

- **AC-01**：`pom.xml` Java source/target = 21，Spring Boot parent = 3.5.11
- **AC-02**：`package.json` packageManager = pnpm@10.30.1
- **AC-03**：`.nvmrc` = 22.22.0
- **AC-04**：`docker-compose.yml` 使用 postgres:16.12-alpine
- **AC-05**：所有 package.json 无 `^` 版本号
- **AC-06**：`.env.example` 使用 `VITE_APP_BASE_API`，无 `VITE_API_BASE_URL`
- **AC-07**：`gate-manifest.sh` 包含 7 列审计字段检查 + caret 扫描 + env 变量检查

---

## 关键约束

- 禁止：`^` 版本号 · `VITE_API_BASE_URL` · 非锁定的 Docker 镜像版本
- Maven Wrapper 版本：3.9.9
- Node.js 版本：22.22.0（.nvmrc）
- pnpm 版本：10.30.1（packageManager 字段锁定）

## 可 Bundle

可与 Phase 1 一起执行，但必须分开两个 Phase 块输出。
