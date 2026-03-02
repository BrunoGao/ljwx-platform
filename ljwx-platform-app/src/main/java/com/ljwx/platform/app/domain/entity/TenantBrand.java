package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

/**
 * 租户品牌配置实体
 *
 * @author LJWX Platform
 * @since Phase 38
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class TenantBrand extends BaseEntity {

    /**
     * 主键 ID
     */
    private Long id;

    /**
     * 品牌名称
     */
    private String brandName;

    /**
     * Logo URL
     */
    private String logoUrl;

    /**
     * Favicon URL
     */
    private String faviconUrl;

    /**
     * 主色
     */
    private String primaryColor;

    /**
     * 辅助色
     */
    private String secondaryColor;

    /**
     * 背景色
     */
    private String backgroundColor;

    /**
     * 登录页背景图
     */
    private String loginBgUrl;

    /**
     * 登录页标语
     */
    private String loginSlogan;

    /**
     * 版权信息
     */
    private String copyrightText;

    /**
     * 备案号
     */
    private String icpNumber;

    /**
     * 页脚链接（JSONB）
     */
    private String footerLinks;

    /**
     * 移动端图标
     */
    private String mobileIconUrl;

    /**
     * 移动端启动页
     */
    private String mobileSplashUrl;

    /**
     * 自定义 CSS
     */
    private String customCss;

    /**
     * 页脚链接内部类
     */
    @Data
    public static class FooterLink {
        /**
         * 链接文本
         */
        private String text;

        /**
         * 链接 URL
         */
        private String url;

        /**
         * 是否在新窗口打开
         */
        private Boolean openInNewTab;
    }
}
