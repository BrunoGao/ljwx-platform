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
| 预计文件数 | 12 |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-architecture.md` — §POM 依赖声明（app 部分）
- `spec/04-database.md` — V001 ~ V009
- `spec/05-backend-config.md` — §application.yml 骨架
- `spec/01-constraints.md` — §审计字段、§RBAC 权限
- `spec/08-output-rules.md`

## 任务

实现 ljwx-platform-app 骨架：
1. Spring Boot 主类（LjwxPlatformApplication）
2. application.yml 配置文件
3. Flyway V001-V009 迁移脚本（基础表 + 种子数据）

## 数据库设计

### 核心表结构

#### sys_user（V002）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 用户 ID（Snowflake） |
| username | VARCHAR(50) | NOT NULL, UNIQUE(tenant_id, username) | 登录用户名（租户内唯一） |
| password | VARCHAR(255) | NOT NULL | BCrypt(cost=10) 密码哈希 |
| nickname | VARCHAR(100) | NULLABLE | 昵称 |
| email | VARCHAR(100) | NULLABLE | 邮箱 |
| phone | VARCHAR(20) | NULLABLE | 手机号 |
| avatar | VARCHAR(500) | NULLABLE | 头像 URL |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 状态：1=启用 0=禁用 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0 | 租户 ID |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除标记 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁版本号 |

#### sys_role（V003）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 角色 ID |
| role_name | VARCHAR(50) | NOT NULL | 角色名称 |
| role_code | VARCHAR(50) | NOT NULL, UNIQUE(tenant_id, role_code) | 角色编码（租户内唯一） |
| description | VARCHAR(200) | NULLABLE | 描述 |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 状态：1=启用 0=禁用 |
| + 7 列审计字段 | | | |

#### sys_permission（V004）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 权限 ID |
| permission_code | VARCHAR(100) | NOT NULL, UNIQUE | 权限编码（如 system:user:list） |
| permission_name | VARCHAR(100) | NOT NULL | 权限名称 |
| resource_type | VARCHAR(20) | NOT NULL | 资源类型（menu/button/api） |
| + 7 列审计字段 | | | |

### Flyway 文件清单

- **V001__init_schema.sql**: 初始化 schema（如需要）
- **V002__create_user.sql**: 创建 sys_user 表
- **V003__create_role.sql**: 创建 sys_role 表
- **V004__create_permission.sql**: 创建 sys_permission 表
- **V005__seed_default_tenant.sql**: 插入默认租户（tenant_id=0）
- **V006__seed_admin_user.sql**: 插入 admin 用户（密码 Admin@12345，BCrypt cost=10）
- **V007__seed_permissions.sql**: 插入所有 RBAC 权限字符串（参考 spec/01-constraints.md）
- **V008__seed_admin_role.sql**: 插入 admin 角色
- **V009__assign_admin_role.sql**: 为 admin 用户分配 admin 角色及所有权限

## 应用配置

### Spring Boot 主类

```java
// com.ljwx.platform.app.LjwxPlatformApplication
@SpringBootApplication(scanBasePackages = "com.ljwx.platform")
@EnableCaching
@EnableAsync
@MapperScan("com.ljwx.platform.app.infra.mapper")
public class LjwxPlatformApplication {
    public static void main(String[] args) {
        SpringApplication.run(LjwxPlatformApplication.class, args);
    }
}
```

关键注解：
- `@SpringBootApplication`: 启用自动配置
- `scanBasePackages = "com.ljwx.platform"`: 扫描所有模块的组件
- `@EnableCaching`: 启用 Caffeine 缓存（用于字典和配置）
- `@EnableAsync`: 启用异步任务（用于操作日志）
- `@MapperScan`: 扫描 MyBatis Mapper 接口

### application.yml 配置

关键配置项：
- **Server**: port=8080, context-path=/
- **DataSource**: PostgreSQL JDBC 连接（支持环境变量）
- **Flyway**: enabled=true, locations=classpath:db/migration
- **Quartz**: job-store-type=jdbc, 集群模式
- **MyBatis**: mapper-locations=classpath*:mapper/**/*.xml
- **SpringDoc**: api-docs=/v3/api-docs, swagger-ui=/swagger-ui.html
- **JWT**: secret, access-token-expiration=1800s, refresh-token-expiration=604800s
- **File**: base-path=./uploads
- **Cache**: type=caffeine, maximumSize=500, expireAfterWrite=600s
- **Management**: health probes for K8s

## 业务逻辑

### 应用启动
1. Spring Boot 启动，扫描所有模块的组件
2. Flyway 自动执行 V001-V009 迁移脚本
3. MyBatis 初始化 Mapper 接口
4. Quartz 初始化调度器
5. 应用就绪，监听 8080 端口

### 数据库初始化
1. V001: 初始化 schema（如需要）
2. V002-V004: 创建 sys_user, sys_role, sys_permission 表
3. V005: 插入默认租户（tenant_id=0）
4. V006: 插入 admin 用户（username=admin, password=BCrypt(Admin@12345, cost=10)）
5. V007: 插入所有 RBAC 权限（参考 spec/01-constraints.md §RBAC）
6. V008: 插入 admin 角色
7. V009: 为 admin 用户分配 admin 角色及所有权限

## 测试用例

### 应用启动测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-05-01 | 应用正常启动 | 启动 Spring Boot 应用 | 启动成功，无异常 | P0 |
| TC-05-02 | Flyway 迁移执行 | 检查 flyway_schema_history 表 | V001-V009 全部执行成功 | P0 |
| TC-05-03 | 健康检查端点 | GET /actuator/health | 200, status=UP | P0 |
| TC-05-04 | Swagger UI 可访问 | GET /swagger-ui.html | 200, 页面正常加载 | P1 |

### 数据库初始化测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-05-05 | sys_user 表创建 | 查询 sys_user 表结构 | 表存在，含 7 列审计字段 | P0 |
| TC-05-06 | sys_role 表创建 | 查询 sys_role 表结构 | 表存在，含 7 列审计字段 | P0 |
| TC-05-07 | sys_permission 表创建 | 查询 sys_permission 表结构 | 表存在，含 7 列审计字段 | P0 |
| TC-05-08 | admin 用户创建 | 查询 sys_user 表 | admin 用户存在，密码为 BCrypt 哈希 | P0 |
| TC-05-09 | 权限种子数据 | 查询 sys_permission 表 | 所有 RBAC 权限已插入 | P0 |
| TC-05-10 | admin 角色分配 | 查询 sys_user_role 表 | admin 用户已分配 admin 角色 | P0 |

### 配置验证测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-05-11 | 数据源连接 | 启动应用，检查日志 | 数据源连接成功 | P0 |
| TC-05-12 | MyBatis Mapper 扫描 | 启动应用，检查日志 | Mapper 接口已注册 | P0 |
| TC-05-13 | Quartz 初始化 | 启动应用，检查 QRTZ_* 表 | Quartz 表已创建 | P0 |
| TC-05-14 | Caffeine 缓存配置 | 启动应用，检查日志 | 缓存管理器已初始化 | P1 |

### 安全测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-05-15 | admin 密码强度 | 查询 sys_user 表 | 密码为 BCrypt 哈希，长度 60 字符 | P0 |
| TC-05-16 | 密码 BCrypt cost | 验证密码哈希 | cost=10 | P0 |
| TC-05-17 | 租户隔离初始化 | 查询所有表 | 所有业务表含 tenant_id 列 | P0 |

## 验收条件映射

| 验收条件 | 来源 | 测试用例 | Gate 维度 |
|---------|------|----------|----------|
| AC-01 | F-005 | TC-05-01 | — |
| AC-02 | F-005 | TC-05-02 | R02 |
| AC-03 | F-005 | TC-05-05, TC-05-06, TC-05-07 | R02, R07 |
| AC-04 | F-005 | TC-05-08, TC-05-15, TC-05-16 | R02 |
| AC-05 | F-005 | TC-05-09 | R02 |

## 预期生成文件

| 文件路径 | 类型 | Gate 关联 |
|---------|------|----------|
| ljwx-platform-app/pom.xml | POM | R01 |
| .../app/LjwxPlatformApplication.java | Main Class | — |
| .../resources/application.yml | Config | — |
| .../db/migration/V001__init_schema.sql | Migration | R02 |
| .../db/migration/V002__create_user.sql | Migration | R02 |
| .../db/migration/V003__create_role.sql | Migration | R02 |
| .../db/migration/V004__create_permission.sql | Migration | R02 |
| .../db/migration/V005__seed_default_tenant.sql | Migration | R02 |
| .../db/migration/V006__seed_admin_user.sql | Migration | R02 |
| .../db/migration/V007__seed_permissions.sql | Migration | R02 |
| .../db/migration/V008__seed_admin_role.sql | Migration | R02 |
| .../db/migration/V009__assign_admin_role.sql | Migration | R02 |

## 验收条件

1. `pom.xml` 依赖含 `ljwx-platform-web` + `ljwx-platform-data`
2. application.yml 与 spec/05-backend-config.md 一致
3. V001-V004 的 CREATE TABLE 均含 7 列审计字段
4. V006 中 admin 密码使用 BCrypt cost=10 的 hash
5. V007 包含 spec/01-constraints.md §RBAC 中的所有权限字符串
6. 无 `IF NOT EXISTS`
7. `./mvnw compile -pl ljwx-platform-app` 通过
8. 应用启动成功，健康检查返回 200

## 关键约束

- 所有业务表（sys_user, sys_role, sys_permission）必须含 7 列审计字段
- Flyway 迁移文件禁止使用 `IF NOT EXISTS`
- admin 密码必须使用 BCrypt cost=10 哈希
- application.yml 中数据库连接支持环境变量
- Spring Boot 主类必须扫描 `com.ljwx.platform` 包

## 可 Bundle

可与 Phase 4 一起执行。
