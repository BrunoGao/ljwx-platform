package com.ljwx.platform.app.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ljwx.platform.app.domain.entity.SysTenant;
import com.ljwx.platform.app.infra.mapper.SysTenantMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.Result;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * 租户生命周期过滤器。
 *
 * <p>拦截所有请求，检查当前租户的生命周期状态：
 * <ul>
 *   <li>FROZEN（冻结）→ 返回 403 Forbidden</li>
 *   <li>CANCELLED（注销）→ 返回 403 Forbidden</li>
 *   <li>ACTIVE（正常）→ 放行</li>
 * </ul>
 *
 * <p>Order=2，在 TenantContextFilter（Order=1）之后执行，确保 TenantContext 已设置。
 */
@Slf4j
@Component
@Order(2)
@RequiredArgsConstructor
public class TenantLifecycleFilter extends OncePerRequestFilter {

    private final CurrentTenantHolder tenantHolder;
    private final SysTenantMapper tenantMapper;
    private final ObjectMapper objectMapper;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        Long tenantId = tenantHolder.getTenantId();

        // 未认证或超级租户（tenantId=0）放行
        if (tenantId == null || tenantId.longValue() == 0L) {
            filterChain.doFilter(request, response);
            return;
        }

        // 查询租户状态
        SysTenant tenant = tenantMapper.selectById(tenantId);
        if (tenant == null) {
            log.warn("Tenant not found: tenantId={}", tenantId);
            writeErrorResponse(response, ErrorCode.RESOURCE_NOT_FOUND, "租户不存在");
            return;
        }

        String lifecycleStatus = tenant.getLifecycleStatus();

        // 检查冻结状态
        if ("FROZEN".equals(lifecycleStatus)) {
            log.warn("Tenant is frozen: tenantId={}, reason={}", tenantId, tenant.getFrozenReason());
            writeErrorResponse(response, ErrorCode.PERMISSION_DENIED, "租户已冻结");
            return;
        }

        // 检查注销状态
        if ("CANCELLED".equals(lifecycleStatus)) {
            log.warn("Tenant is cancelled: tenantId={}, reason={}", tenantId, tenant.getCancelledReason());
            writeErrorResponse(response, ErrorCode.PERMISSION_DENIED, "租户已注销");
            return;
        }

        // 正常状态，放行
        filterChain.doFilter(request, response);
    }

    private void writeErrorResponse(HttpServletResponse response, ErrorCode errorCode, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json;charset=UTF-8");

        Result<Void> result = Result.fail(errorCode.getCode(), message);
        String json = objectMapper.writeValueAsString(result);
        response.getWriter().write(json);
    }
}
