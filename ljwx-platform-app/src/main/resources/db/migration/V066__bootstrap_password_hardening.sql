-- =============================================================
-- V066: Harden bootstrap password handling
-- Replace the legacy seeded admin hash with a managed placeholder hash.
-- Blank out the unsafe import default password config; runtime must use env.
-- =============================================================

UPDATE sys_user
SET password = '$2b$10$uCp2Sw/d8Ipq5FrRNfBUt.FOq8dszFY/XHDumEDk3u5IhrZz1JW9S',
    updated_by = 0,
    updated_time = CURRENT_TIMESTAMP,
    version = version + 1
WHERE username = 'admin'
  AND password = '$2a$10$PnWlMR8Ox6UMTZj7Zm9uO.wSqzbjVt04UbeJ7q3RxDe8TSIP6efz2'
  AND deleted = FALSE;

UPDATE sys_config
SET config_value = '',
    remark = '由环境变量 LJWX_BOOTSTRAP_USER_IMPORT_INITIAL_PASSWORD 提供',
    updated_by = 0,
    updated_time = CURRENT_TIMESTAMP,
    version = version + 1
WHERE config_key = 'sys.user.initPassword'
  AND deleted = FALSE;
