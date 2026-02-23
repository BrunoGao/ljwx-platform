-- =============================================================
-- V020: Seed initial system configuration data
-- =============================================================

INSERT INTO sys_config (id, config_name, config_key, config_value, config_type, remark, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version)
VALUES
    (2000000001, '主框架页-默认皮肤样式名称',   'sys.index.skinName',       'skin-blue',          1, '蓝色 skin-blue、绿色 skin-green、紫色 skin-purple、红色 skin-red、黄色 skin-yellow',          1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (2000000002, '用户管理-账号初始密码',         'sys.user.initPassword',    'Admin@12345',        1, '初始化密码 Admin@12345',                                                                     1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (2000000003, '主框架页-侧边栏主题',           'sys.index.sideTheme',      'theme-dark',         1, '深色主题 theme-dark、浅色主题 theme-light',                                                  1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (2000000004, '账号自助-是否开启用户注册功能', 'sys.account.registerUser', 'false',              1, '是否开启注册用户功能（true 开启，false 关闭）',                                              1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1),
    (2000000005, '文件上传-允许的文件后缀',       'sys.file.allowedSuffix',   'jpg,jpeg,png,gif,webp,svg,pdf,doc,docx,xls,xlsx,ppt,pptx,txt,csv,zip,rar,7z,mp4,mp3', 1, '允许上传的文件后缀白名单', 1, 1, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP, FALSE, 1);
