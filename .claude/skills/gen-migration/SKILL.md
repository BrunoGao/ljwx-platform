---
name: gen-migration
description: Generate a Flyway SQL migration file following LJWX project conventions. Use when adding new database tables or schema changes.
argument-hint: "[phase-number] [description]"
disable-model-invocation: true
---

# 生成 Flyway 迁移文件

为 Phase $ARGUMENTS 生成符合项目规范的 Flyway 迁移 SQL 文件。

## 步骤

1. 查看现有迁移文件，确定版本号：
   ```bash
   ls ljwx-platform-app/src/main/resources/db/migration/
   ```

2. 确定新文件名：
   - 格式：`V{phase}_{seq}__{description}.sql`
   - 示例：`V15_1__create_notification_table.sql`
   - seq 从当前 phase 最大序号 +1 开始

3. 生成 SQL 文件，遵循以下规则：

   **业务表模板（必须含 7 列审计字段）**：
   ```sql
   CREATE TABLE t_example (
       id           BIGINT        NOT NULL COMMENT '主键',
       name         VARCHAR(100)  NOT NULL COMMENT '名称',
       -- 7 个审计字段 — 业务表必须全部包含
       tenant_id    BIGINT        NOT NULL DEFAULT 0    COMMENT '租户ID',
       created_by   BIGINT        NOT NULL DEFAULT 0    COMMENT '创建人',
       created_time TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
       updated_by   BIGINT        NOT NULL DEFAULT 0    COMMENT '更新人',
       updated_time TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
       deleted      TINYINT(1)    NOT NULL DEFAULT 0    COMMENT '逻辑删除(0:正常,1:删除)',
       version      INT           NOT NULL DEFAULT 0    COMMENT '乐观锁版本号',
       PRIMARY KEY (id),
       INDEX idx_tenant_id (tenant_id)
   ) COMMENT = '示例表';
   ```

   **硬规则**：
   - 禁止 `IF NOT EXISTS`
   - 禁止 `DROP TABLE`（除非有 ADR 批准）
   - 禁止修改已应用的迁移文件
   - Quartz 系统表（`QRTZ_*`）不含审计字段

4. 验证迁移文件创建后后端仍可编译：
   ```bash
   mvn clean compile -f pom.xml -q
   ```

5. 如果是 Quartz 相关表，参考 Spring Boot Quartz 官方 SQL schema，不添加审计字段。
