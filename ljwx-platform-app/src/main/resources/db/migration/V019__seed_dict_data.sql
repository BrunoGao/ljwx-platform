-- =============================================================
-- V019: Seed initial dictionary data
-- =============================================================

-- Seed dict types
INSERT INTO sys_dict_type (id, dict_name, dict_type, status, remark, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version)
VALUES
    (1900000001, '用户性别', 'sys_user_sex',    1, '用户性别列表',   1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1900000002, '菜单状态', 'sys_show_hide',   1, '菜单状态列表',   1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1900000003, '系统开关', 'sys_normal_disable', 1, '系统开关列表', 1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1900000004, '任务状态', 'sys_job_status',  1, '任务状态列表',   1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1900000005, '通知类型', 'sys_notice_type', 1, '通知类型列表',   1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1);

-- Seed dict data: sys_user_sex
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, sort_order, status, is_default, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version)
VALUES
    (1910000001, 'sys_user_sex', '男', '0', 0, 1, TRUE,  1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1910000002, 'sys_user_sex', '女', '1', 1, 1, FALSE, 1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1910000003, 'sys_user_sex', '未知', '2', 2, 1, FALSE, 1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1);

-- Seed dict data: sys_show_hide
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, sort_order, status, is_default, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version)
VALUES
    (1910000004, 'sys_show_hide', '显示', '0', 0, 1, TRUE,  1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1910000005, 'sys_show_hide', '隐藏', '1', 1, 1, FALSE, 1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1);

-- Seed dict data: sys_normal_disable
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, sort_order, status, is_default, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version)
VALUES
    (1910000006, 'sys_normal_disable', '正常', '0', 0, 1, TRUE,  1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1910000007, 'sys_normal_disable', '停用', '1', 1, 1, FALSE, 1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1);

-- Seed dict data: sys_job_status
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, sort_order, status, is_default, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version)
VALUES
    (1910000008, 'sys_job_status', '正常', '1', 0, 1, TRUE,  1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1910000009, 'sys_job_status', '暂停', '0', 1, 1, FALSE, 1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1);

-- Seed dict data: sys_notice_type
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, sort_order, status, is_default, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version)
VALUES
    (1910000010, 'sys_notice_type', '通知', '1', 0, 1, TRUE,  1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (1910000011, 'sys_notice_type', '公告', '2', 1, 1, FALSE, 1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1);
