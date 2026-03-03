package com.ljwx.platform.web.filter;

import com.ljwx.platform.security.util.SecurityUtils;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;

/**
 * Tenant context filter that manages tenant ID resolution for each request.
 *
 * <h3>Super Admin Tenant Switching</h3>
 * <p>Super admins (tenant_id = 0) can switch tenant context by providing the
 * {@code X-Tenant-Id} header. This allows them to:
 * <ul>
 *   <li>Query data for a specific tenant by setting {@code X-Tenant-Id: 1}</li>
 *   <li>Query data across all tenants by omitting the header (tenant_id = 0)</li>
 * </ul>
 *
 * <h3>Regular User Isolation</h3>
 * <p>Regular users (tenant_id != 0) cannot switch tenants. The {@code X-Tenant-Id}
 * header is ignored for non-super-admin users, and their tenant ID is always
 * taken from the JWT claims.
 *
 * <h3>Execution Order</h3>
 * <p>This filter runs with {@code @Order(1)} to ensure it executes after
 * {@link com.ljwx.platform.security.filter.JwtAuthenticationFilter} has populated
 * the {@link SecurityContextHolder}.
 *
 * <h3>DAG Compliance</h3>
 * <p>This filter is in the {@code web} module and depends on:
 * <ul>
 *   <li>{@code security} module — {@link SecurityUtils}</li>
 *   <li>{@code core} module — indirectly via security</li>
 * </ul>
 * It does NOT depend on {@code data} or {@code app} modules.
 */
@Slf4j
@Component
@Order(1)
@RequiredArgsConstructor
public class TenantContextFilter extends OncePerRequestFilter {

    private static final String TENANT_ID_HEADER = "X-Tenant-Id";

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        try {
            Long tenantId = resolveTenantId(request);
            if (tenantId != null) {
                // Update the authentication details with the resolved tenant ID
                updateTenantContext(tenantId);
            }
            filterChain.doFilter(request, response);
        } finally {
            // No explicit cleanup needed — SecurityContextHolder is cleared
            // by Spring Security's SecurityContextHolderFilter
        }
    }

    /**
     * Resolves the tenant ID for the current request.
     *
     * <p>Resolution logic:
     * <ol>
     *   <li>If domain-based tenant ID is present (from TenantDomainFilter) → use it</li>
     *   <li>If user is super admin (tenant_id = 0):
     *     <ul>
     *       <li>If {@code X-Tenant-Id} header is present → use header value</li>
     *       <li>Otherwise → use 0 (query all tenants)</li>
     *     </ul>
     *   </li>
     *   <li>If user is regular user → use JWT tenant_id (ignore header)</li>
     *   <li>If unauthenticated → return {@code null}</li>
     * </ol>
     *
     * @param request the HTTP request
     * @return resolved tenant ID, or {@code null} for unauthenticated requests
     */
    private Long resolveTenantId(HttpServletRequest request) {
        // 1. 优先从域名识别（由 TenantDomainFilter 设置）
        Long tenantIdFromDomain = (Long) request.getAttribute("TENANT_ID_FROM_DOMAIN");
        if (tenantIdFromDomain != null) {
            log.debug("Resolved tenant from domain: {}", tenantIdFromDomain);
            return tenantIdFromDomain;
        }

        // 2. 从认证信息获取
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }

        Long userTenantId = extractTenantIdFromAuth(authentication);
        if (userTenantId == null) {
            return null;
        }

        // 3. Super admin can switch tenant context via header
        if (Long.valueOf(0).equals(userTenantId)) {
            String headerTenantId = request.getHeader(TENANT_ID_HEADER);
            if (StringUtils.hasText(headerTenantId)) {
                try {
                    Long targetTenantId = Long.parseLong(headerTenantId);
                    log.debug("Super admin switching to tenant: {}", targetTenantId);
                    return targetTenantId;
                } catch (NumberFormatException e) {
                    log.warn("Invalid X-Tenant-Id header value: {}", headerTenantId);
                    return userTenantId;
                }
            }
        }

        // 4. Regular user or super admin without header
        return userTenantId;
    }

    /**
     * Updates the tenant ID in the authentication details.
     *
     * <p>This allows the {@link com.ljwx.platform.security.context.SecurityContextTenantHolder}
     * to read the updated tenant ID.
     *
     * @param tenantId the tenant ID to set
     */
    @SuppressWarnings("unchecked")
    private void updateTenantContext(Long tenantId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null) {
            Object details = authentication.getDetails();
            if (details instanceof Map<?, ?> map) {
                ((Map<String, Object>) map).put("tenantId", tenantId);
            }
        }
    }

    /**
     * Extracts tenant ID from authentication details.
     */
    @SuppressWarnings("unchecked")
    private Long extractTenantIdFromAuth(Authentication authentication) {
        Object details = authentication.getDetails();
        if (details instanceof Map<?, ?> map) {
            Object tenantId = ((Map<String, Object>) map).get("tenantId");
            if (tenantId instanceof Long l) return l;
            if (tenantId instanceof Integer i) return i.longValue();
            if (tenantId instanceof Number n) return n.longValue();
        }
        return null;
    }
}
