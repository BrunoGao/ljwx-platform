package com.ljwx.platform.core.context;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Map;

/**
 * 当前租户上下文接口。
 *
 * <p>实现由 ljwx-platform-security 模块提供（SecurityContextTenantHolder），
 * 通过 Spring 依赖注入注册为 Bean。data 模块的 TenantLineInterceptor
 * 通过此接口获取 tenant_id，自动追加 WHERE tenant_id = ? 实现行级隔离。
 *
 * <p>接口与实现分离，符合 DAG 约束：
 * core ← {security, data}，data 仅依赖 core 中的此接口。
 */
public interface CurrentTenantHolder {

    /**
     * 获取当前请求所属租户的 ID。
     *
     * @return 租户 ID，未认证时返回 {@code null}
     */
    Long getTenantId();

    /**
     * Legacy static accessor for historical call sites.
     *
     * <p>Reads tenant ID from Spring Security authentication details map:
     * {@code details.tenantId}.
     *
     * @return tenant ID or {@code null} when unavailable
     */
    static Long get() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            return null;
        }
        Object details = authentication.getDetails();
        if (details instanceof Map<?, ?> detailsMap) {
            return toLong(detailsMap.get("tenantId"));
        }
        return null;
    }

    private static Long toLong(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.longValue();
        }
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (NumberFormatException ex) {
            return null;
        }
    }
}
