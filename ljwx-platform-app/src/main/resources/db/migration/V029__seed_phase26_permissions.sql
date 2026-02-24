-- =============================================================
-- V029: Seed Phase-26 permissions for dept, monitor, online-user,
--       login-log, and tenant-package controllers.
--       Grant all to admin role (id=1).
-- V023 ended at permission id=28, role_permission id=28.
-- =============================================================

-- ─────────────────────────────────────────
-- New permissions
-- ─────────────────────────────────────────
INSERT INTO sys_permission (id, tenant_id, code, name, created_by, updated_by, version) VALUES
(29, 1, 'system:dept:list',             '部门查询',     0, 0, 1),
(30, 1, 'system:dept:detail',           '部门详情',     0, 0, 1),
(31, 1, 'system:dept:create',           '部门新增',     0, 0, 1),
(32, 1, 'system:dept:update',           '部门修改',     0, 0, 1),
(33, 1, 'system:dept:delete',           '部门删除',     0, 0, 1),
(34, 1, 'system:monitor:server',        '服务器监控',   0, 0, 1),
(35, 1, 'system:monitor:jvm',           'JVM监控',      0, 0, 1),
(36, 1, 'system:monitor:cache',         '缓存监控',     0, 0, 1),
(37, 1, 'system:online:list',           '在线用户查询', 0, 0, 1),
(38, 1, 'system:online:kickout',        '强制下线',     0, 0, 1),
(39, 1, 'system:log:login:list',        '登录日志查询', 0, 0, 1),
(40, 1, 'system:tenant-package:list',   '套餐查询',     0, 0, 1),
(41, 1, 'system:tenant-package:detail', '套餐详情',     0, 0, 1),
(42, 1, 'system:tenant-package:create', '套餐新增',     0, 0, 1),
(43, 1, 'system:tenant-package:update', '套餐修改',     0, 0, 1),
(44, 1, 'system:tenant-package:delete', '套餐删除',     0, 0, 1),
(45, 1, 'system:user:export',           '用户导出',     0, 0, 1),
(46, 1, 'system:user:import',           '用户导入',     0, 0, 1),
(47, 1, 'system:notice:read',           '通知已读',     0, 0, 1),
(48, 1, 'system:notice:list',           '通知未读数',   0, 0, 1);

-- ─────────────────────────────────────────
-- Grant all new permissions to admin role (id=1)
-- ─────────────────────────────────────────
INSERT INTO sys_role_permission (id, tenant_id, role_id, permission_id, created_by, updated_by, version) VALUES
(29, 1, 1, 29, 0, 0, 1),
(30, 1, 1, 30, 0, 0, 1),
(31, 1, 1, 31, 0, 0, 1),
(32, 1, 1, 32, 0, 0, 1),
(33, 1, 1, 33, 0, 0, 1),
(34, 1, 1, 34, 0, 0, 1),
(35, 1, 1, 35, 0, 0, 1),
(36, 1, 1, 36, 0, 0, 1),
(37, 1, 1, 37, 0, 0, 1),
(38, 1, 1, 38, 0, 0, 1),
(39, 1, 1, 39, 0, 0, 1),
(40, 1, 1, 40, 0, 0, 1),
(41, 1, 1, 41, 0, 0, 1),
(42, 1, 1, 42, 0, 0, 1),
(43, 1, 1, 43, 0, 0, 1),
(44, 1, 1, 44, 0, 0, 1),
(45, 1, 1, 45, 0, 0, 1),
(46, 1, 1, 46, 0, 0, 1),
(47, 1, 1, 47, 0, 0, 1),
(48, 1, 1, 48, 0, 0, 1);
