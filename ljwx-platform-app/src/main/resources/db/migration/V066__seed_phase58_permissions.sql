-- =============================================================
-- V066: Seed Phase-58 permissions for billing, operations dashboard,
--       help docs, and screen APIs. Grant all to admin role (id=1).
-- =============================================================

INSERT INTO sys_permission (id, tenant_id, code, name, created_by, updated_by, version) VALUES
(49, 1, 'system:billing:list',  '计量计费查询', 0, 0, 1),
(50, 1, 'system:ops:dashboard', '运营看板查询', 0, 0, 1),
(51, 1, 'system:help:list',     '帮助文档查询', 0, 0, 1),
(52, 1, 'system:help:query',    '帮助文档详情', 0, 0, 1),
(53, 1, 'system:help:add',      '帮助文档新增', 0, 0, 1),
(54, 1, 'system:help:edit',     '帮助文档修改', 0, 0, 1),
(55, 1, 'system:help:delete',   '帮助文档删除', 0, 0, 1),
(56, 1, 'system:screen:read',   '大屏查询(v1)', 0, 0, 1);

INSERT INTO sys_role_permission (id, tenant_id, role_id, permission_id, created_by, updated_by, version) VALUES
(49, 1, 1, 49, 0, 0, 1),
(50, 1, 1, 50, 0, 0, 1),
(51, 1, 1, 51, 0, 0, 1),
(52, 1, 1, 52, 0, 0, 1),
(53, 1, 1, 53, 0, 0, 1),
(54, 1, 1, 54, 0, 0, 1),
(55, 1, 1, 55, 0, 0, 1),
(56, 1, 1, 56, 0, 0, 1);
