package com.ljwx.platform.app.filter;

import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.logging.MDCKeys;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.slf4j.MDC;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/**
 * Logging filter that injects contextual information into MDC for structured logging.
 *
 * <p>Executed at {@code @Order(2)}, after JWT authentication and tenant context setup.
 * Injects the following MDC keys:
 * <ul>
 *   <li>{@code trace_id} - Unique request trace ID (from X-Trace-Id header or generated)</li>
 *   <li>{@code tenant_id} - Current tenant ID (from SecurityContext)</li>
 *   <li>{@code user_id} - Current user ID (from SecurityContext)</li>
 *   <li>{@code requestUri} - HTTP request URI</li>
 *   <li>{@code requestMethod} - HTTP request method</li>
 *   <li>{@code clientIp} - Client IP address (supports X-Forwarded-For)</li>
 * </ul>
 *
 * <p>All MDC keys are cleared in the {@code finally} block to prevent thread pool pollution.
 *
 * <p><strong>Important:</strong> {@code trace_id}, {@code tenant_id}, and {@code user_id}
 * are stored as JSON fields in log entries, NOT as Loki labels, to avoid high cardinality issues.
 */
@Component
@Order(2)
@RequiredArgsConstructor
public class LoggingFilter extends OncePerRequestFilter {

    private static final String TRACE_ID_HEADER = "X-Trace-Id";
    private static final String X_FORWARDED_FOR = "X-Forwarded-For";

    private final CurrentTenantHolder currentTenantHolder;
    private final CurrentUserHolder currentUserHolder;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {
        try {
            // 1. Trace ID: read from header or generate
            String traceId = request.getHeader(TRACE_ID_HEADER);
            if (traceId == null || traceId.isBlank()) {
                traceId = generateTraceId();
            }
            MDC.put(MDCKeys.TRACE_ID, traceId);

            // 2. Tenant ID: from SecurityContext (may be null for public endpoints)
            Long tenantId = currentTenantHolder.getTenantId();
            MDC.put(MDCKeys.TENANT_ID, tenantId != null ? String.valueOf(tenantId) : "0");

            // 3. User ID: from SecurityContext (may be null for public endpoints)
            Long userId = currentUserHolder.getUserId();
            MDC.put(MDCKeys.USER_ID, userId != null ? String.valueOf(userId) : "0");

            // 4. Request metadata
            MDC.put(MDCKeys.REQUEST_URI, request.getRequestURI());
            MDC.put(MDCKeys.REQUEST_METHOD, request.getMethod());
            MDC.put(MDCKeys.CLIENT_IP, getClientIp(request));

            // 5. Set trace ID in response header for client correlation
            response.setHeader(TRACE_ID_HEADER, traceId);

            filterChain.doFilter(request, response);
        } finally {
            // Always clear MDC to prevent thread pool pollution
            MDC.clear();
        }
    }

    /**
     * Generates a unique trace ID (16-character hex string).
     *
     * @return trace ID
     */
    private String generateTraceId() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 16);
    }

    /**
     * Extracts client IP address, supporting X-Forwarded-For header.
     *
     * @param request HTTP request
     * @return client IP address
     */
    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader(X_FORWARDED_FOR);
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            // X-Forwarded-For may contain multiple IPs: "client, proxy1, proxy2"
            // The first IP is the original client
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
