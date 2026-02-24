-- =============================================================
-- V023: Seed sys_menu data + new system:menu:* permissions
-- New permissions IDs 24-28 (V007 ended at 23)
-- =============================================================

-- ─────────────────────────────────────────
-- New permissions: system:menu:*
-- ─────────────────────────────────────────
INSERT INTO sys_permission (id, tenant_id, code, name, created_by, updated_by, version) VALUES
(24, 1, 'system:menu:list',   '菜单查询', 0, 0, 1),
(25, 1, 'system:menu:detail', '菜单详情', 0, 0, 1),
(26, 1, 'system:menu:create', '菜单新增', 0, 0, 1),
(27, 1, 'system:menu:update', '菜单修改', 0, 0, 1),
(28, 1, 'system:menu:delete', '菜单删除', 0, 0, 1);

-- ─────────────────────────────────────────
-- Grant new permissions to admin role (id=1)
-- ─────────────────────────────────────────
INSERT INTO sys_role_permission (id, tenant_id, role_id, permission_id, created_by, updated_by, version) VALUES
(24, 1, 1, 24, 0, 0, 1),
(25, 1, 1, 25, 0, 0, 1),
(26, 1, 1, 26, 0, 0, 1),
(27, 1, 1, 27, 0, 0, 1),
(28, 1, 1, 28, 0, 0, 1);

-- ─────────────────────────────────────────
-- sys_menu seed: system management directory + sub-menus
-- menu_type: 0=directory 1=menu 2=button
-- ─────────────────────────────────────────
INSERT INTO sys_menu (id, tenant_id, parent_id, name, path, component, icon, sort, menu_type, permission, visible, created_by, updated_by, version) VALUES
( 1, 1, 0, '系统管理',   '/system',         '',                        'Setting',       1, 0, '',                   1, 0, 0, 1),
( 2, 1, 1, '用户管理',   '/system/user',    'system/user/index',       'User',          1, 1, 'user:read',          1, 0, 0, 1),
( 3, 1, 1, '角色管理',   '/system/role',    'system/role/index',       'UserFilled',    2, 1, 'role:read',          1, 0, 0, 1),
( 4, 1, 1, '菜单管理',   '/system/menu',    'system/menu/index',       'Menu',          3, 1, 'system:menu:list',   1, 0, 0, 1),
( 5, 1, 1, '部门管理',   '/system/dept',    'system/dept/index',       'OfficeBuilding',4, 1, '',                   1, 0, 0, 1),
( 6, 1, 1, '字典管理',   '/system/dict',    'system/dict/index',       'Collection',    5, 1, 'dict:read',          1, 0, 0, 1),
( 7, 1, 1, '配置管理',   '/system/config',  'system/config/index',     'Tools',         6, 1, 'config:read',        1, 0, 0, 1),
( 8, 1, 1, '日志管理',   '/system/log',     'system/log/index',        'Document',      7, 1, 'log:read',           1, 0, 0, 1),
( 9, 1, 1, '文件管理',   '/system/file',    'system/file/index',       'FolderOpened',  8, 1, 'file:read',          1, 0, 0, 1),
(10, 1, 1, '公告管理',   '/system/notice',  'system/notice/index',     'Bell',          9, 1, 'notice:read',        1, 0, 0, 1);
