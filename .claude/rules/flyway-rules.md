---
paths:
  - "ljwx-platform-app/src/main/resources/db/migration/**/*.sql"
---

# Flyway 迁移规范 — LJWX Platform

## 文件命名

格式：`V{phase}_{seq}__{description}.sql`

示例：
- `V1_1__create_sys_user.sql`
- `V6_1__seed_admin_user.sql`
- `V15_2__add_notification_index.sql`

迁移文件路径：`ljwx-platform-app/src/main/resources/db/migration/`

## DDL 硬规则

1. **禁止** `IF NOT EXISTS`（Flyway 负责版本管理，不需要幂等 DDL）
2. 业务表（非 Quartz）**必须**含 7 列审计字段，均 NOT NULL + 有 DEFAULT：

```sql
CREATE TABLE sys_example (
    id           BIGINT       NOT NULL,
    name         VARCHAR(100) NOT NULL,
    -- 7 个审计字段，业务表必须全部包含
    tenant_id    BIGINT       NOT NULL DEFAULT 0,
    created_by   BIGINT       NOT NULL DEFAULT 0,
    created_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by   BIGINT       NOT NULL DEFAULT 0,
    updated_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted      TINYINT      NOT NULL DEFAULT 0,
    version      INT          NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
);
```

3. Quartz 系统表（`QRTZ_*`）**不得**含审计字段
4. **禁止** `DROP TABLE`（除非 ADR 明确批准）
5. **禁止** `TRUNCATE`

## 已应用迁移不可修改

一旦 Flyway 迁移文件被 apply，**永远不能修改**。
追加变更需创建新的迁移文件（更高版本号）。

## 种子数据

- 管理员初始密码必须通过 `LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD` 注入，数据库仅存 BCrypt cost=10 哈希
- 写在 V006 种子 SQL 中
