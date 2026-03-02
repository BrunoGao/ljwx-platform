package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.hibernate.validator.constraints.URL;

import java.util.List;

/**
 * 租户品牌配置更新 DTO
 *
 * @author LJWX Platform
 * @since Phase 38
 */
@Data
public class TenantBrandUpdateDTO {

    /**
     * 品牌名称
     */
    @NotBlank(message = "品牌名称不能为空")
    @Size(max = 100, message = "品牌名称长度不能超过100")
    private String brandName;

    /**
     * Logo URL
     */
    @URL(message = "Logo URL 格式不正确")
    private String logoUrl;

    /**
     * Favicon URL
     */
    @URL(message = "Favicon URL 格式不正确")
    private String faviconUrl;

    /**
     * 主色
     */
    @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "主色必须为 #RRGGBB 格式")
    private String primaryColor;

    /**
     * 辅助色
     */
    @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "辅助色必须为 #RRGGBB 格式")
    private String secondaryColor;

    /**
     * 背景色
     */
    @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "背景色必须为 #RRGGBB 格式")
    private String backgroundColor;

    /**
     * 登录页背景图
     */
    @URL(message = "登录页背景图 URL 格式不正确")
    private String loginBgUrl;

    /**
     * 登录页标语
     */
    @Size(max = 200, message = "登录页标语长度不能超过200")
    private String loginSlogan;

    /**
     * 版权信息
     */
    @Size(max = 200, message = "版权信息长度不能超过200")
    private String copyrightText;

    /**
     * 备案号
     */
    @Size(max = 50, message = "备案号长度不能超过50")
    private String icpNumber;

    /**
     * 页脚链接
     */
    private List<FooterLinkDTO> footerLinks;

    /**
     * 移动端图标
     */
    @URL(message = "移动端图标 URL 格式不正确")
    private String mobileIconUrl;

    /**
     * 移动端启动页
     */
    @URL(message = "移动端启动页 URL 格式不正确")
    private String mobileSplashUrl;

    /**
     * 自定义 CSS
     */
    @Size(max = 10000, message = "自定义 CSS 长度不能超过10000")
    private String customCss;

    /**
     * 页脚链接 DTO
     */
    @Data
    public static class FooterLinkDTO {
        /**
         * 链接文本
         */
        @NotBlank(message = "链接文本不能为空")
        private String text;

        /**
         * 链接 URL
         */
        @NotBlank(message = "链接 URL 不能为空")
        @URL(message = "链接 URL 格式不正确")
        private String url;

        /**
         * 是否在新窗口打开
         */
        private Boolean openInNewTab;
    }
}
