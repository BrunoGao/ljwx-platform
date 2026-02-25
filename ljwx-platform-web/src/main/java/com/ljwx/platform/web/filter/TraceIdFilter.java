package com.ljwx.platform.web.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.core.annotation.Order;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Map;
import java.util.UUID;

/**
 * 请求链路追踪过滤器。
 *
 * <p>职责：
 * <ul>
 *   <li>从请求头 {@code X-Trace-Id} 读取 traceId，若无则生成（UUID 前 16 位）</li>
 *   <li>写入 MDC：traceId、tenantId、userId</li>
 *   <li>响应头写入 {@code X-Trace-Id}</li>
 *   <li>finally 块清理 MDC</li>
 * </ul>
 *
 * <p>order=0（最高优先级，在 XssFilter 之前）。
 */
@Component
@Order(0)
public class TraceIdFilter implements Filter {

    private static final String TRACE_ID_HEADER = "X-Trace-Id";
    private static final String MDC_TRACE_ID = "traceId";
    private static final String MDC_TENANT_ID = "tenantId";
    private static final String MDC_USER_ID = "userId";
    private static final String ANONYMOUS = "anonymous";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        try {
            // 1. 读取或生成 traceId
            String traceId = httpRequest.getHeader(TRACE_ID_HEADER);
            if (traceId == null || traceId.isBlank()) {
                traceId = UUID.randomUUID().toString().replace("-", "").substring(0, 16);
            }
            MDC.put(MDC_TRACE_ID, traceId);

            // 2. 从 SecurityContext 提取 tenantId 和 userId
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.isAuthenticated()
                    && !"anonymousUser".equals(authentication.getPrincipal())
                    && authentication.getDetails() instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<String, Object> details = (Map<String, Object>) authentication.getDetails();
                Object tenantId = details.get("tenantId");
                Object userId = details.get("userId");
                MDC.put(MDC_TENANT_ID, tenantId != null ? tenantId.toString() : ANONYMOUS);
                MDC.put(MDC_USER_ID, userId != null ? userId.toString() : ANONYMOUS);
            } else {
                MDC.put(MDC_TENANT_ID, ANONYMOUS);
                MDC.put(MDC_USER_ID, ANONYMOUS);
            }

            // 3. 响应头写入 traceId
            httpResponse.setHeader(TRACE_ID_HEADER, traceId);

            chain.doFilter(request, response);
        } finally {
            // 4. 清理 MDC
            MDC.clear();
        }
    }
}
