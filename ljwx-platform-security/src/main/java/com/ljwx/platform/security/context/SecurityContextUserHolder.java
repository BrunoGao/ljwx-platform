package com.ljwx.platform.security.context;

import com.ljwx.platform.core.context.CurrentUserHolder;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * {@link CurrentUserHolder} implementation that reads the current authenticated user
 * from Spring Security's {@link SecurityContextHolder}.
 *
 * <p>The {@code details} field of the {@link Authentication} object is expected to be a
 * {@code Map<String, Object>} set by {@link com.ljwx.platform.security.filter.JwtAuthenticationFilter}
 * containing at least the keys {@code "userId"} and {@code "username"}.
 *
 * <p>Returns {@code null} for both methods when no authentication is present
 * (e.g., public endpoints like login/refresh).
 */
@Component
public class SecurityContextUserHolder implements CurrentUserHolder {

    @Override
    public Long getUserId() {
        Map<String, Object> details = extractDetails();
        if (details == null) {
            return null;
        }
        Object userId = details.get("userId");
        if (userId instanceof Long l) return l;
        if (userId instanceof Integer i) return i.longValue();
        if (userId instanceof Number n) return n.longValue();
        return null;
    }

    @Override
    public String getUsername() {
        Map<String, Object> details = extractDetails();
        if (details == null) {
            return null;
        }
        Object username = details.get("username");
        return username instanceof String s ? s : null;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> extractDetails() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return null;
        }
        Object details = auth.getDetails();
        if (details instanceof Map<?, ?> map) {
            return (Map<String, Object>) map;
        }
        return null;
    }
}
