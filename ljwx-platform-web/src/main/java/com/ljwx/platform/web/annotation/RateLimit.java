package com.ljwx.platform.web.annotation;

import java.lang.annotation.*;

/**
 * API 限流注解 — 基于 Caffeine 令牌桶，按 key 限流。
 *
 * <p>用法示例：
 * <pre>{@code
 * @RateLimit(key = "user:{userId}", limit = 100, window = 60)
 * @PostMapping("/export")
 * public Result<Void> export() { ... }
 * }</pre>
 *
 * <p>key 支持占位符：
 * <ul>
 *   <li>{@code {userId}} — 从 SecurityContext 提取当前用户 ID</li>
 *   <li>{@code {ip}}     — 客户端 IP 地址</li>
 * </ul>
 *
 * <p>由 {@link com.ljwx.platform.web.interceptor.RateLimitInterceptor} 处理。
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RateLimit {

    /**
     * 限流 key 模板，支持 {@code {userId}}、{@code {ip}} 占位符。
     */
    String key() default "default";

    /**
     * 时间窗口内允许的最大请求次数。
     */
    int limit() default 100;

    /**
     * 时间窗口大小（秒）。
     */
    int window() default 60;
}
