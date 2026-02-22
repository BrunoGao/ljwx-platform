# LJWX Platform 规格文档索引

## 文档职责边界

| 文件 | 内容 | 单一事实源规则 |
|------|------|---------------|
| `CLAUDE.md` | 硬规则 + 版本锁定 + 代码风格 + 反模式 | **版本号的唯一来源**。其他文件引用不重复 |
| `spec/01-constraints.md` | 审计字段、多租户、JWT、RBAC、Quartz、日志、文件、缓存、TS 约束的完整定义 | 约束细节的唯一来源 |
| `spec/02-architecture.md` | 仓库结构、模块依赖 DAG、Core 接口定义、POM 依赖声明 | 架构的唯一来源 |
| `spec/03-api.md` | 统一响应格式、错误码、完整路由表 | API 合约的唯一来源 |
| `spec/04-database.md` | Flyway 迁移文件清单 + DDL 规则 | 数据库 schema 的唯一来源 |
| `spec/05-backend-config.md` | application.yml 骨架 | 后端配置的唯一来源 |
| `spec/06-frontend-config.md` | pnpm-workspace、root package.json、.npmrc、.nvmrc、.env.example、Admin / Mobile / Screen 各端配置 | 前端配置的唯一来源 |
| `spec/07-devops.md` | Docker Compose、CI Gate 脚本、smoke-test、工具链安装策略 | DevOps 的唯一来源 |
| `spec/08-output-rules.md` | Phase 输出格式、完整性规则 | 输出规范的唯一来源 |
| `spec/phase/phase-{NN}.md` | 每个 Phase 的具体任务、读取清单、验收条件 | Phase 执行计划的唯一来源 |

## 防漂移规则

1. **版本号**只在 `CLAUDE.md` 的"版本锁定"段中维护。其他 spec 文件需要引用版本时，写"版本见 CLAUDE.md"
2. **同一约束**不在两个文件中重复定义。在唯一来源中定义，其他文件通过"见 spec/XX-xxx.md §章节名"引用
3. 如发现任何不一致，以"单一事实源"文件为准
4. 变更日志和审阅记录存放在 `docs/adr/` 目录，不进入生成上下文
