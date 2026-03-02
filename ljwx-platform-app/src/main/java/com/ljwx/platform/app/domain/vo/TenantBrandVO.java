package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 租户品牌配置 VO
 *
 * @author LJWX Platform
 * @since Phase 38
 */
@Data
public class TenantBrandVO {

    /**
     * 主键
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
     * 页脚链接
     */
    private List<FooterLinkVO> footerLinks;

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
     * 创建时间
     */
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    private LocalDateTime updatedTime;

    /**
     * 页脚链接 VO
     */
    @Data
    public static class FooterLinkVO {
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
