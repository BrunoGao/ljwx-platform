package com.ljwx.platform.core.context;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Map;

/**
 * 当前登录用户上下文接口。
 *
 * <p>实现由 ljwx-platform-security 模块提供（SecurityContextUserHolder），
 * 通过 Spring 依赖注入注册为 Bean。data 模块的 AuditFieldInterceptor
 * 通过此接口读取当前用户 ID 写入 created_by / updated_by 审计字段。
 *
 * <p>接口与实现分离，符合 DAG 约束：
 * core ← {security, data}，data 仅依赖 core 中的此接口。
 */
public interface CurrentUserHolder {

    /**
     * 获取当前登录用户的 ID。
     *
     * @return 用户 ID，未登录时返回 {@code null}
     */
    Long getUserId();

    /**
     * 获取当前登录用户的用户名。
     *
     * @return 用户名，未登录时返回 {@code null}
     */
    String getUsername();

    /**
     * Legacy static accessor for historical call sites.
     *
     * <p>Reads user ID from Spring Security details map:
     * {@code details.userId}.
     *
     * @return user ID or {@code null} when unavailable
     */
    static Long get() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            return null;
        }
        Object details = authentication.getDetails();
        if (details instanceof Map<?, ?> detailsMap) {
            return toLong(detailsMap.get("userId"));
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
