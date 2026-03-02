-- Phase 38: 租户品牌配置表
CREATE TABLE sys_tenant_brand (
    id                  BIGINT          NOT NULL,
    brand_name          VARCHAR(100)    NOT NULL,
    logo_url            VARCHAR(500),
    favicon_url         VARCHAR(500),
    primary_color       VARCHAR(20)     NOT NULL DEFAULT '#1890ff',
    secondary_color     VARCHAR(20),
    background_color    VARCHAR(20),
    login_bg_url        VARCHAR(500),
    login_slogan        VARCHAR(200),
    copyright_text      VARCHAR(200),
    icp_number          VARCHAR(50),
    footer_links        JSONB,
    mobile_icon_url     VARCHAR(500),
    mobile_splash_url   VARCHAR(500),
    custom_css          TEXT,
    tenant_id           BIGINT          NOT NULL DEFAULT 0,
    created_by          BIGINT          NOT NULL DEFAULT 0,
    created_time        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL DEFAULT 0,
    updated_time        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted             BOOLEAN         NOT NULL DEFAULT FALSE,
    version             INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- 唯一索引：每个租户只能有一条品牌配置
CREATE UNIQUE INDEX uk_tenant_id ON sys_tenant_brand (tenant_id, deleted);

-- 租户 ID 索引
CREATE INDEX idx_tenant_id ON sys_tenant_brand (tenant_id);

COMMENT ON TABLE sys_tenant_brand IS '租户品牌配置表';
COMMENT ON COLUMN sys_tenant_brand.id IS '主键（雪花 ID）';
COMMENT ON COLUMN sys_tenant_brand.brand_name IS '品牌名称';
COMMENT ON COLUMN sys_tenant_brand.logo_url IS 'Logo URL';
COMMENT ON COLUMN sys_tenant_brand.favicon_url IS 'Favicon URL';
COMMENT ON COLUMN sys_tenant_brand.primary_color IS '主色';
COMMENT ON COLUMN sys_tenant_brand.secondary_color IS '辅助色';
COMMENT ON COLUMN sys_tenant_brand.background_color IS '背景色';
COMMENT ON COLUMN sys_tenant_brand.login_bg_url IS '登录页背景图';
COMMENT ON COLUMN sys_tenant_brand.login_slogan IS '登录页标语';
COMMENT ON COLUMN sys_tenant_brand.copyright_text IS '版权信息';
COMMENT ON COLUMN sys_tenant_brand.icp_number IS '备案号';
COMMENT ON COLUMN sys_tenant_brand.footer_links IS '页脚链接（JSONB）';
COMMENT ON COLUMN sys_tenant_brand.mobile_icon_url IS '移动端图标';
COMMENT ON COLUMN sys_tenant_brand.mobile_splash_url IS '移动端启动页';
COMMENT ON COLUMN sys_tenant_brand.custom_css IS '自定义 CSS';
