package com.ljwx.platform.app.util;

import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * CSS 安全过滤器
 * 用于过滤自定义 CSS 中的危险代码
 *
 * @author LJWX Platform
 * @since Phase 38
 */
public class CssSanitizer {

    /**
     * CSS 属性白名单
     */
    private static final Set<String> ALLOWED_CSS_PROPERTIES = Set.of(
        "color", "background-color", "background", "font-size", "font-family", "font-weight",
        "margin", "margin-top", "margin-right", "margin-bottom", "margin-left",
        "padding", "padding-top", "padding-right", "padding-bottom", "padding-left",
        "border", "border-radius", "border-color", "border-width", "border-style",
        "width", "height", "max-width", "max-height", "min-width", "min-height",
        "display", "position", "top", "right", "bottom", "left",
        "text-align", "text-decoration", "line-height", "letter-spacing",
        "opacity", "z-index", "overflow", "box-shadow", "text-shadow"
    );

    /**
     * 危险模式（正则表达式）
     */
    private static final List<Pattern> DANGEROUS_PATTERNS = List.of(
        Pattern.compile("<script", Pattern.CASE_INSENSITIVE),
        Pattern.compile("javascript:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("expression\\s*\\(", Pattern.CASE_INSENSITIVE),
        Pattern.compile("@import", Pattern.CASE_INSENSITIVE),
        Pattern.compile("behavior\\s*:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("-moz-binding\\s*:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("url\\s*\\((?!\\s*(data:|https:))", Pattern.CASE_INSENSITIVE)
    );

    /**
     * 过滤自定义 CSS，移除危险代码
     *
     * @param css 原始 CSS
     * @return 过滤后的安全 CSS
     * @throws IllegalArgumentException 如果包含危险代码
     */
    public static String sanitize(String css) {
        if (css == null || css.isBlank()) {
            return "";
        }

        // 1. 检查危险模式
        for (Pattern pattern : DANGEROUS_PATTERNS) {
            if (pattern.matcher(css).find()) {
                throw new IllegalArgumentException("CSS contains dangerous code: " + pattern.pattern());
            }
        }

        // 2. 解析 CSS 并验证属性白名单
        // 使用属性级正则提取，保留白名单中的声明
        Pattern propertyPattern = Pattern.compile("([a-z-]+)\\s*:\\s*([^;]+);");
        Matcher matcher = propertyPattern.matcher(css);

        StringBuilder sanitized = new StringBuilder();
        while (matcher.find()) {
            String property = matcher.group(1).trim().toLowerCase();
            String value = matcher.group(2).trim();

            // 验证属性是否在白名单中
            if (ALLOWED_CSS_PROPERTIES.contains(property)) {
                sanitized.append(property).append(": ").append(value).append("; ");
            }
        }

        return sanitized.toString();
    }
}
