-- =============================================================
-- V025: Seed sys_dept — default root department and sub-departments
-- =============================================================

INSERT INTO sys_dept (id, parent_id, name, sort, leader, phone, email, status,
                      tenant_id, created_by, created_time, updated_by, updated_time, deleted, version)
VALUES
    (1, 0, '总公司', 0, '管理员', '', '', 1,
     1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (2, 1, '技术部', 1, '', '', '', 1,
     1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (3, 1, '市场部', 2, '', '', '', 1,
     1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (4, 1, '财务部', 3, '', '', '', 1,
     1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1);
