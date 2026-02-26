# 数据库迁移（Flyway）

## 规则

- 不使用 `IF NOT EXISTS`
- 所有迁移文件位于 `ljwx-platform-app/src/main/resources/db/migration/`
- Quartz 表不含审计字段
- 其余业务表必须含 7 列审计字段（见 `spec/01-constraints.md` §审计字段）
- DDL 与 DML 分离；仅明确约定允许的 seed 迁移可包含 DML

## 迁移清单（实施现状）

| 文件 | 说明 |
|------|------|
| V001__init_schema.sql | 创建 `sys_tenant` 表 |
| V002__create_user.sql | 创建 `sys_user` 表 |
| V003__create_role.sql | 创建 `sys_role`、`sys_user_role` |
| V004__create_permission.sql | 创建 `sys_permission`、`sys_role_permission` |
| V005__seed_default_tenant.sql | 插入默认租户 |
| V006__seed_admin_user.sql | 插入 admin 用户（BCrypt） |
| V007__seed_permissions.sql | 插入基础权限字符串 |
| V008__seed_admin_role.sql | 插入 admin 角色 |
| V009__assign_admin_role.sql | admin 角色赋权/赋用户 |
| V010__create_quartz_tables.sql | Quartz 标准 PostgreSQL DDL（无审计字段） |
| V011__create_sys_job.sql | 创建 `sys_job` |
| V012__create_sys_dict_type.sql | 创建 `sys_dict_type` |
| V013__create_sys_dict_data.sql | 创建 `sys_dict_data` |
| V014__create_sys_config.sql | 创建 `sys_config` |
| V015__create_sys_operation_log.sql | 创建 `sys_operation_log` |
| V016__create_sys_login_log.sql | 创建 `sys_login_log`（基础列） |
| V017__create_sys_file.sql | 创建 `sys_file` |
| V018__create_sys_notice.sql | 创建 `sys_notice` |
| V019__seed_dict_data.sql | 字典类型/字典数据种子 |
| V020__seed_config_data.sql | 系统配置种子 |
| V021__create_indexes.sql | 常用业务索引 |
| V022__create_sys_menu.sql | 创建 `sys_menu` |
| V023__seed_sys_menu.sql | 菜单及菜单权限种子 |
| V024__create_sys_dept.sql | 创建 `sys_dept` |
| V025__seed_sys_dept.sql | 部门种子 |
| V026__create_sys_login_log.sql | **ALTER** `sys_login_log`：新增 `ip_address`、`user_agent`、`login_time`、`message` |
| V027__create_sys_tenant_package.sql | 创建 `sys_tenant_package` + `ALTER TABLE sys_tenant ADD package_id` |
| V028__create_sys_notice_user.sql | 创建 `sys_notice_user` |
| V029__seed_phase26_permissions.sql | 补齐 Phase 21-25 权限种子并赋权 admin |
| V030__create_sys_data_change_log.sql | 创建 `sys_data_change_log` |
| V031__create_sys_frontend_error.sql | 创建 `sys_frontend_error` |
