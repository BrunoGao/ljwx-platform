package com.ljwx.platform.web.interceptor;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.ljwx.platform.web.annotation.RateLimit;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

/**
 * API 限流拦截器 — 基于 Caffeine 固定窗口计数器实现。
 *
 * <p>仅对标注了 {@link RateLimit} 的 Controller 方法生效。
 * key 模板中的 {@code {userId}} 从 Spring Security 上下文提取，
 * {@code {ip}} 从请求头或 remoteAddr 提取。
 *
 * <p>DAG 合规：web 模块依赖 security，可合法 import SecurityContextHolder。
 */
@Component
public class RateLimitInterceptor implements HandlerInterceptor {

    /**
     * 计数器缓存：key = 解析后的限流 key + ":" + 窗口编号，value = 请求计数。
     * 过期时间设为 5 分钟，覆盖最大 window=300s 的场景。
     */
    private final Cache<String, AtomicLong> counterCache = Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(5))
            .build();

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws IOException {
        if (!(handler instanceof HandlerMethod handlerMethod)) {
            return true;
        }

        RateLimit rateLimit = handlerMethod.getMethodAnnotation(RateLimit.class);
        if (rateLimit == null) {
            return true;
        }

        String resolvedKey = resolveKey(rateLimit.key(), request);
        // 固定窗口编号：当前时间 / 窗口秒数
        long windowIndex = System.currentTimeMillis() / (rateLimit.window() * 1000L);
        String cacheKey = resolvedKey + ":" + windowIndex;

        AtomicLong counter = counterCache.get(cacheKey, k -> new AtomicLong(0));
        long count = counter.incrementAndGet();

        if (count > rateLimit.limit()) {
            response.setStatus(429);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                    "{\"code\":429,\"message\":\"Too Many Requests\",\"data\":null}");
            return false;
        }

        return true;
    }

    // ─────────────────────────────── key 解析 ──────────────────────────────────

    private String resolveKey(String keyTemplate, HttpServletRequest request) {
        String key = keyTemplate;
        if (key.contains("{userId}")) {
            Long userId = extractUserId();
            key = key.replace("{userId}", userId != null ? userId.toString() : "anonymous");
        }
        if (key.contains("{ip}")) {
            key = key.replace("{ip}", extractClientIp(request));
        }
        return key;
    }

    @SuppressWarnings("unchecked")
    private Long extractUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return null;
        }
        Object details = auth.getDetails();
        if (details instanceof Map<?, ?> map) {
            Object userId = ((Map<String, Object>) map).get("userId");
            if (userId instanceof Long l) return l;
            if (userId instanceof Number n) return n.longValue();
        }
        return null;
    }

    private String extractClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip != null && !ip.isBlank()) {
            // X-Forwarded-For 可能包含多个 IP，取第一个
            return ip.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
