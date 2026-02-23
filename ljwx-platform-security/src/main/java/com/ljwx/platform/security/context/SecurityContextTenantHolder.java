package com.ljwx.platform.security.context;

import com.ljwx.platform.core.context.CurrentTenantHolder;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * {@link CurrentTenantHolder} implementation that reads the current tenant ID
 * from Spring Security's {@link SecurityContextHolder}.
 *
 * <p>The {@code details} field of the {@link Authentication} object is expected to be a
 * {@code Map<String, Object>} set by {@link com.ljwx.platform.security.filter.JwtAuthenticationFilter}
 * containing the key {@code "tenantId"}.
 *
 * <p>Returns {@code null} when no authentication is present
 * (e.g., public endpoints like login/refresh).
 * The data module's {@code TenantLineInterceptor} treats {@code null} as "bypass"
 * only for public endpoints; all authenticated requests must carry a valid tenant ID.
 */
@Component
public class SecurityContextTenantHolder implements CurrentTenantHolder {

    @Override
    public Long getTenantId() {
        Map<String, Object> details = extractDetails();
        if (details == null) {
            return null;
        }
        Object tenantId = details.get("tenantId");
        if (tenantId instanceof Long l) return l;
        if (tenantId instanceof Integer i) return i.longValue();
        if (tenantId instanceof Number n) return n.longValue();
        return null;
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
