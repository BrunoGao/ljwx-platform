# 数据库迁移（Flyway）

## 规则

- 不使用 `IF NOT EXISTS`
- 所有 DDL 在 `V{NNN}__description.sql` 中
- Quartz 表不含审计字段
- 其余业务表必须含 7 列审计字段（见 spec/01-constraints.md §审计字段）
- 迁移文件位于 `ljwx-platform-app/src/main/resources/db/migration/`

## 迁移清单

| 文件 | 说明 |
|------|------|
| V001__init_schema.sql | 创建 sys_tenant 表 |
| V002__create_user.sql | 创建 sys_user 表 |
| V003__create_role.sql | 创建 sys_role、sys_user_role 表 |
| V004__create_permission.sql | 创建 sys_permission、sys_role_permission 表 |
| V005__seed_default_tenant.sql | 插入默认租户 (id=1, name='默认租户') |
| V006__seed_admin_user.sql | 插入 admin 用户 (BCrypt hash of Admin@12345, cost=10) |
| V007__seed_permissions.sql | 插入所有权限字符串 |
| V008__seed_admin_role.sql | 插入 admin 角色并关联全部权限 |
| V009__assign_admin_role.sql | 将 admin 角色分配给 admin 用户 |
| V010__create_quartz_tables.sql | Quartz 标准 PostgreSQL DDL（无审计字段） |
| V011__create_sys_job.sql | 创建 sys_job 业务表（含审计字段） |
| V012__create_sys_dict_type.sql | 字典类型表 |
| V013__create_sys_dict_data.sql | 字典数据表 |
| V014__create_sys_config.sql | 系统配置表 |
| V015__create_sys_operation_log.sql | 操作日志表 |
| V016__create_sys_login_log.sql | 登录日志表 |
| V017__create_sys_file.sql | 文件管理表 |
| V018__create_sys_notice.sql | 通知表 |
| V019__seed_dict_data.sql | 初始字典数据（性别、状态等） |
| V020__seed_config_data.sql | 初始配置数据 |
| V021__create_indexes.sql | 常用索引 |
