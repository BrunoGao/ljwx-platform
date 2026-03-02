package com.ljwx.platform.security.util;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Map;

/**
 * Security utility methods for accessing current user information.
 *
 * <h3>Super Admin Detection</h3>
 * <p>A user is considered a super admin if their {@code tenant_id} is 0.
 * Super admins have the following privileges:
 * <ul>
 *   <li>Can query data across all tenants (tenant filter is bypassed)</li>
 *   <li>Can switch tenant context via {@code X-Tenant-Id} header</li>
 *   <li>Still subject to permission checks (not unlimited access)</li>
 * </ul>
 *
 * <h3>DAG Compliance</h3>
 * <p>This class is in the {@code security} module and only depends on Spring Security.
 * It does NOT import from {@code data} or {@code app} modules.
 */
public final class SecurityUtils {

    private SecurityUtils() {
        throw new UnsupportedOperationException("Utility class");
    }

    /**
     * Checks if the current authenticated user is a super admin.
     *
     * <p>A super admin is identified by {@code tenant_id = 0} in the JWT claims.
     *
     * @return {@code true} if the current user is a super admin, {@code false} otherwise
     */
    public static boolean isSuperAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return false;
        }

        Long tenantId = getTenantId(authentication);
        return tenantId != null && Long.valueOf(0).equals(tenantId);
    }

    /**
     * Gets the current user's tenant ID from the authentication details.
     *
     * @return tenant ID, or {@code null} if not available
     */
    public static Long getCurrentTenantId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        return getTenantId(authentication);
    }

    /**
     * Gets the current user's ID from the authentication details.
     *
     * @return user ID, or {@code null} if not available
     */
    public static Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        return getUserId(authentication);
    }

    /**
     * Gets the current username from the authentication principal.
     *
     * @return username, or {@code null} if not available
     */
    public static String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof String) {
            return (String) principal;
        }
        return null;
    }

    /**
     * Extracts tenant ID from authentication details.
     */
    private static Long getTenantId(Authentication authentication) {
        Map<String, Object> details = extractDetails(authentication);
        if (details == null) {
            return null;
        }
        Object tenantId = details.get("tenantId");
        return convertToLong(tenantId);
    }

    /**
     * Extracts user ID from authentication details.
     */
    private static Long getUserId(Authentication authentication) {
        Map<String, Object> details = extractDetails(authentication);
        if (details == null) {
            return null;
        }
        Object userId = details.get("userId");
        return convertToLong(userId);
    }

    /**
     * Extracts the details map from authentication.
     */
    @SuppressWarnings("unchecked")
    private static Map<String, Object> extractDetails(Authentication authentication) {
        Object details = authentication.getDetails();
        if (details instanceof Map<?, ?> map) {
            return (Map<String, Object>) map;
        }
        return null;
    }

    /**
     * Converts an object to Long, handling Integer and Number types.
     */
    private static Long convertToLong(Object value) {
        if (value instanceof Long l) return l;
        if (value instanceof Integer i) return i.longValue();
        if (value instanceof Number n) return n.longValue();
        return null;
    }
}
