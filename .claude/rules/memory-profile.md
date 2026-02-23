# LJWX Platform — 项目档案

本文件由 Claude Code 自动维护，记录不变的项目事实。

## 技术栈

| 层 | 技术 | 版本 |
|---|------|------|
| 后端语言 | Java | 21 |
| 框架 | Spring Boot | 3.5.11 |
| ORM | MyBatis-Plus | 3.0.5 |
| 数据库 | PostgreSQL | 16.12 |
| 迁移 | Flyway | 由 Spring Boot BOM 管理 |
| 前端框架 | Vue | ~3.5.28 |
| 路由 | Vue Router | ~5.0.2 |
| 状态管理 | Pinia | ~3.0.4 |
| UI 组件 | Element Plus | ~2.13.2 |
| 包管理 | pnpm | 10.30.1 |
| 构建 | Vite | ~7.3.1 |
| 类型 | TypeScript | ~5.9.3 |

## 模块结构

```
ljwx-platform/
├── ljwx-platform-core/      # 基础类，无外部依赖
├── ljwx-platform-security/  # 认证授权，依赖 core
├── ljwx-platform-data/      # 数据访问，依赖 core（不依赖 security）
├── ljwx-platform-web/       # Web 层，依赖 security + data
├── ljwx-platform-app/       # 启动模块，依赖 web
├── ljwx-platform-admin/     # Vue 3 管理后台
├── ljwx-platform-mobile/    # uni-app 移动端
└── ljwx-platform-screen/    # 数据大屏
```

## 多租户策略

- 应用层隔离：每张业务表含 `tenant_id` 列
- TenantLineInterceptor 自动注入 tenant_id（从 JWT claim 提取）
- DTO / 请求参数**禁止**传 tenantId
- SecurityContext 是 tenantId 的唯一来源

## 关键配置

- 后端编译：`mvn clean compile -f pom.xml -q`
- 前端类型检查：`pnpm run type-check`（在 ljwx-platform-admin/）
- Gate 检查：`bash scripts/gates/gate-all.sh <phase-number>`
- 预检：`bash scripts/preflight/preflight-check.sh`

## Phase 系统

- Phase 0–19（当前规划）
- 每个 Phase 的说明在 `spec/phase/phase-NN.md`
- 完成记录写入 `PHASE_MANIFEST.txt`
