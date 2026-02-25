---
phase: 5
title: "App Skeleton"
targets:
  backend: true
  frontend: false
depends_on: [4]
bundle_with: [4]
scope:
  - "ljwx-platform-app/pom.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/LjwxPlatformApplication.java"
  - "ljwx-platform-app/src/main/resources/application.yml"
  - "ljwx-platform-app/src/main/resources/db/migration/V001__init_schema.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V002__create_user.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V003__create_role.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V004__create_permission.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V005__seed_default_tenant.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V006__seed_admin_user.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V007__seed_permissions.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V008__seed_admin_role.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V009__assign_admin_role.sql"
---
# Phase 5 — 应用骨架与数据库初始化 (App Skeleton)

| 项目 | 值 |
|-----|---|
| Phase | 5 |
| 模块 | ljwx-platform-app |
| Feature | F-005 (应用启动与基础数据) |
| 前置依赖 | Phase 4 (Web Module) |
| 测试契约 | `spec/tests/phase-05-app.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-architecture.md` — §POM 依赖声明（app 部分）
- `spec/04-database.md` — V001 ~ V009
- `spec/05-backend-config.md` — §application.yml 骨架
- `spec/01-constraints.md` — §审计字段、§RBAC 权限
- `spec/08-output-rules.md`

---

## 数据库契约

### 表结构

#### sys_user（V002）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 用户 ID（雪花） |
| username | VARCHAR(50) | NOT NULL, UNIQUE(tenant_id, username) | 登录名（租户内唯一） |
| password | VARCHAR(255) | NOT NULL | BCrypt(cost=10) |
| nickname | VARCHAR(100) | NULLABLE | 昵称 |
| email | VARCHAR(100) | NULLABLE | 邮箱 |
| phone | VARCHAR(20) | NULLABLE | 手机号 |
| avatar | VARCHAR(500) | NULLABLE | 头像 URL |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 1=启用 0=禁用 |
| + 7 列审计字段 | | NOT NULL + DEFAULT | tenant_id / created_by / created_time / updated_by / updated_time / deleted / version |

#### sys_role（V003）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 角色 ID |
| name | VARCHAR(100) | NOT NULL | 角色名称 |
| code | VARCHAR(50) | NOT NULL, UNIQUE(tenant_id, code) | 角色编码（租户内唯一） |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 1=启用 0=禁用 |
| remark | VARCHAR(500) | NULLABLE | 备注 |
| + 7 列审计字段 | | NOT NULL + DEFAULT | 同上 |

#### sys_permission（V004）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 权限 ID |
| code | VARCHAR(100) | NOT NULL, UNIQUE(tenant_id, code) | 权限字符串（如 system:user:list） |
| name | VARCHAR(200) | NULLABLE | 权限名称 |
| remark | VARCHAR(500) | NULLABLE | 备注 |
| + 7 列审计字段 | | NOT NULL + DEFAULT | 同上 |

### Flyway 文件

| 文件 | 内容 |
|------|------|
| V001__init_schema.sql | Schema 初始化（若需要） |
| V002__create_user.sql | 建 sys_user 表 + 索引 |
| V003__create_role.sql | 建 sys_role 表 + 索引 |
| V004__create_permission.sql | 建 sys_permission 表 + 索引 |
| V005__seed_default_tenant.sql | 插入默认租户（tenant_id=0） |
| V006__seed_admin_user.sql | 插入 admin 用户（密码 BCrypt cost=10） |
| V007__seed_permissions.sql | 插入所有 RBAC 权限（参考 spec/01-constraints.md §RBAC） |
| V008__seed_admin_role.sql | 插入 admin 角色 |
| V009__assign_admin_role.sql | 为 admin 分配 admin 角色及所有权限 |

禁止：`IF NOT EXISTS`、建表文件中混入 DML。

---

## 主类契约

```
LjwxPlatformApplication
  注解：@SpringBootApplication(scanBasePackages = "com.ljwx.platform")
        @EnableCaching   ← Caffeine（字典 / 配置）
        @EnableAsync     ← 操作日志异步写入
        @MapperScan("com.ljwx.platform.app.infra.mapper")
```

---

## application.yml 契约

| 配置项 | 要求 |
|--------|------|
| server.port | 8080 |
| datasource | PostgreSQL JDBC，连接参数支持环境变量 |
| flyway | enabled=true, locations=classpath:db/migration |
| mybatis-plus.mapper-locations | classpath*:mapper/**/*.xml |
| spring.quartz | job-store-type=jdbc，集群模式 |
| springdoc | api-docs=/v3/api-docs，swagger-ui=/swagger-ui.html |
| jwt | secret / access-token-expiration=1800s / refresh-token-expiration=604800s |
| spring.cache | type=caffeine，maximumSize=500，expireAfterWrite=600s |
| management | health probes for K8s（liveness / readiness） |

---

## 业务规则

- **BL-05-01**：Flyway 按版本号顺序执行 V001→V009，迁移失败则应用拒绝启动
- **BL-05-02**：V006 admin 密码必须是 `BCrypt(Admin@12345, cost=10)` 的哈希值，禁止明文
- **BL-05-03**：V007 权限列表必须覆盖 spec/01-constraints.md §RBAC 中所有权限字符串
- **BL-05-04**：所有业务表（V002-V004）必须含 7 列审计字段，均 NOT NULL + DEFAULT

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-05-app.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-05-01 | 应用正常启动，无异常 | P0 |
| TC-05-02 | Flyway V001-V009 全部成功 | P0 |
| TC-05-03 | GET /actuator/health → 200, UP | P0 |
| TC-05-04 | sys_user/role/permission 表含 7 列审计字段 | P0 |
| TC-05-05 | admin 密码为 BCrypt 哈希（60字符），cost=10 | P0 |
| TC-05-06 | V007 权限种子数据完整 | P0 |

---

## 验收条件

- **AC-01**：`pom.xml` 依赖含 `ljwx-platform-web`
- **AC-02**：`application.yml` 与 `spec/05-backend-config.md` 一致
- **AC-03**：V002-V004 建表均含 7 列审计字段，无 `IF NOT EXISTS`
- **AC-04**：V006 admin 密码为 BCrypt cost=10 哈希
- **AC-05**：V007 包含 `spec/01-constraints.md §RBAC` 中的所有权限字符串
- **AC-06**：`./mvnw compile -pl ljwx-platform-app` 通过，应用启动健康检查 200

---

## 关键约束

- 禁止：`IF NOT EXISTS` · 建表文件混 DML · 明文密码
- 所有业务表 7 列审计字段：NOT NULL + DEFAULT
- 数据库连接参数必须支持环境变量（`${DB_URL:jdbc:...}`）
- 主类 scanBasePackages 必须为 `"com.ljwx.platform"`（覆盖所有子模块）

## 可 Bundle

可与 Phase 4 一起执行。
