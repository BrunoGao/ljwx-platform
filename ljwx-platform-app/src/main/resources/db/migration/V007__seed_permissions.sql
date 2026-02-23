-- =============================================================
-- V007: Seed all RBAC permissions (spec/01-constraints.md §RBAC)
-- 23 permissions in resource:action format
-- =============================================================

INSERT INTO sys_permission (id, tenant_id, code, name, created_by, updated_by, version) VALUES
( 1, 1, 'user:read',    '用户查询',     0, 0, 1),
( 2, 1, 'user:write',   '用户管理',     0, 0, 1),
( 3, 1, 'user:delete',  '用户删除',     0, 0, 1),
( 4, 1, 'role:read',    '角色查询',     0, 0, 1),
( 5, 1, 'role:write',   '角色管理',     0, 0, 1),
( 6, 1, 'role:delete',  '角色删除',     0, 0, 1),
( 7, 1, 'tenant:read',  '租户查询',     0, 0, 1),
( 8, 1, 'tenant:write', '租户管理',     0, 0, 1),
( 9, 1, 'job:read',     '定时任务查询', 0, 0, 1),
(10, 1, 'job:write',    '定时任务管理', 0, 0, 1),
(11, 1, 'job:execute',  '定时任务执行', 0, 0, 1),
(12, 1, 'dict:read',    '字典查询',     0, 0, 1),
(13, 1, 'dict:write',   '字典管理',     0, 0, 1),
(14, 1, 'config:read',  '配置查询',     0, 0, 1),
(15, 1, 'config:write', '配置管理',     0, 0, 1),
(16, 1, 'log:read',     '日志查询',     0, 0, 1),
(17, 1, 'log:export',   '日志导出',     0, 0, 1),
(18, 1, 'file:read',    '文件查询',     0, 0, 1),
(19, 1, 'file:upload',  '文件上传',     0, 0, 1),
(20, 1, 'file:delete',  '文件删除',     0, 0, 1),
(21, 1, 'notice:read',  '通知查询',     0, 0, 1),
(22, 1, 'notice:write', '通知管理',     0, 0, 1),
(23, 1, 'screen:read',  '大屏查询',     0, 0, 1);
