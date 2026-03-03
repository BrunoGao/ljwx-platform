package com.ljwx.platform.app.filter;

import com.ljwx.platform.app.appservice.TenantDomainAppService;
import com.ljwx.platform.app.domain.entity.TenantDomain;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * 租户域名识别过滤器
 *
 * <p>从 Host header 提取域名，查询域名缓存，设置租户上下文。
 *
 * <h3>执行顺序</h3>
 * <p>此过滤器使用 {@code @Order(0)}，必须在 {@link com.ljwx.platform.web.filter.TenantContextFilter}
 * 之前执行，以便 TenantContextFilter 可以读取域名识别的租户 ID。
 *
 * <h3>DAG 合规性</h3>
 * <p>此过滤器位于 {@code app} 模块，依赖：
 * <ul>
 *   <li>{@code app} 模块 — {@link TenantDomainAppService}</li>
 *   <li>{@code core} 模块 — 间接通过 app</li>
 * </ul>
 * 不依赖 {@code web} 模块。
 */
@Slf4j
@Component
@Order(0)
@RequiredArgsConstructor
public class TenantDomainFilter extends OncePerRequestFilter {

    private final TenantDomainAppService tenantDomainAppService;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        // BL-43-05: 从 Host header 提取域名
        String host = request.getHeader("Host");
        if (host == null) {
            filterChain.doFilter(request, response);
            return;
        }

        // 去除端口号
        String domain = host.split(":")[0];

        // BL-43-06: 查询域名缓存
        TenantDomain tenantDomain = tenantDomainAppService.getByDomain(domain);
        if (tenantDomain == null || !"ENABLED".equals(tenantDomain.getStatus())) {
            filterChain.doFilter(request, response);
            return;
        }

        // 设置租户上下文（通过 request attribute 传递给 TenantContextFilter）
        request.setAttribute("TENANT_ID_FROM_DOMAIN", tenantDomain.getTenantId());

        log.debug("Domain {} resolved to tenant {}", domain, tenantDomain.getTenantId());

        filterChain.doFilter(request, response);
    }
}
