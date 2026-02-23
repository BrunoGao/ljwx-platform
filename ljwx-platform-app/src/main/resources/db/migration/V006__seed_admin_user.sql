-- =============================================================
-- V006: Seed admin user
-- username : admin
-- password : Admin@12345
-- hash algo: BCrypt, cost=10
-- Regenerate: new BCryptPasswordEncoder(10).encode("Admin@12345")
-- =============================================================

INSERT INTO sys_user (id, tenant_id, username, password, nickname, status, created_by, updated_by, version)
VALUES (
    1,
    1,
    'admin',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    '系统管理员',
    1,
    0,
    0,
    1
);
