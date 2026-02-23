# ADR-001: 技术栈选型

## 状态

已采纳（2026-02-23）

## 背景

构建企业级多租户 SaaS 平台，需要：
- 强类型安全
- 成熟的安全框架
- 良好的前端工程化
- 简单的数据库迁移管理

## 决策

| 层 | 技术选型 | 理由 |
|---|---------|------|
| 后端 | Spring Boot 3.5 + Java 21 | 成熟生态、强安全框架、LTS |
| ORM | MyBatis-Plus | 多租户拦截器支持好 |
| 前端 | Vue 3 + Vue Router 5 + Pinia | Composition API、TS 支持完善 |
| 数据库 | PostgreSQL 16 | 生产稳定、JSONB 支持 |
| 迁移 | Flyway | 显式版本管理，与 Phase 开发模式匹配 |
| 前端构建 | Vite 7 + pnpm | 快速 HMR、确定性依赖 |
| API 文档 | springdoc-openapi | Spring Boot 3 原生支持 |

## 后果

- Java 21 需要对应 JDK（`JAVA_HOME` 指向 21）
- pnpm 10 作为包管理器，版本由 `packageManager` 字段锁定
- Flyway 迁移文件不可修改（已 apply 的），需新建版本文件追加变更
- Vue Router 5 与 v4 API 不完全兼容，需按 v5 文档编写

## 参考

- [Spring Boot 3.x 文档](https://docs.spring.io/spring-boot/docs/3.5.x/)
- [Vue Router 5 迁移指南](https://router.vuejs.org/guide/migration/v4-to-v5)
- [MyBatis-Plus 多租户插件](https://baomidou.com/plugins/tenant/)
