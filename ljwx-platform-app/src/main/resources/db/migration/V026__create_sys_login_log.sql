-- =============================================================
-- V026: Alter sys_login_log — add ip_address, user_agent, login_time, message columns
-- =============================================================

ALTER TABLE sys_login_log
    ADD COLUMN ip_address  VARCHAR(64)  NOT NULL DEFAULT '',
    ADD COLUMN user_agent  VARCHAR(500) NOT NULL DEFAULT '',
    ADD COLUMN login_time  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    ADD COLUMN message     VARCHAR(255) NOT NULL DEFAULT '';

COMMENT ON COLUMN sys_login_log.ip_address IS '登录IP地址';
COMMENT ON COLUMN sys_login_log.user_agent IS '客户端User-Agent';
COMMENT ON COLUMN sys_login_log.login_time IS '登录时间';
COMMENT ON COLUMN sys_login_log.message    IS '提示消息';
