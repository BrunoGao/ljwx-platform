package com.ljwx.platform.web.filter;

import com.ljwx.platform.data.context.DataScopeContext;
import com.ljwx.platform.security.util.SecurityUtils;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 数据范围上下文过滤器。
 *
 * <p>在每次请求开始时，从 SecurityContext 提取用户信息（userId, deptId, roleIds），
 * 并设置到 {@link DataScopeContext} ThreadLocal 中，供 DataScopeInterceptor 使用。
 *
 * <h3>执行顺序</h3>
 * <p>此过滤器使用 {@code @Order(2)}，在 {@link TenantContextFilter} 之后执行。
 *
 * <h3>DAG 合规</h3>
 * <p>此过滤器位于 {@code web} 模块，依赖：
 * <ul>
 *   <li>{@code security} 模块 — {@link SecurityUtils}</li>
 *   <li>{@code data} 模块 — {@link DataScopeContext}</li>
 * </ul>
 * 不依赖 {@code app} 模块（避免循环依赖）。
 */
@Slf4j
@Component
@Order(2)
public class DataScopeContextFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        try {
            // 从 SecurityContext 获取用户信息
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.isAuthenticated()) {
                Long userId = SecurityUtils.getCurrentUserId();
                Long deptId = extractDeptId(authentication);
                List<Long> roleIds = extractRoleIds(authentication);

                if (userId != null) {
                    // 设置到 ThreadLocal
                    DataScopeContext.set(userId, deptId, roleIds);
                    log.debug("DataScopeContext set: userId={}, deptId={}, roleIds={}",
                            userId, deptId, roleIds);
                }
            }

            filterChain.doFilter(request, response);
        } finally {
            // 清理 ThreadLocal，防止内存泄漏
            DataScopeContext.clear();
        }
    }

    /**
     * 从 Authentication 提取部门 ID。
     */
    private Long extractDeptId(Authentication authentication) {
        Map<String, Object> details = extractDetails(authentication);
        if (details == null) {
            return null;
        }
        Object deptId = details.get("deptId");
        return convertToLong(deptId);
    }

    /**
     * 从 Authentication 提取角色 ID 列表。
     */
    @SuppressWarnings("unchecked")
    private List<Long> extractRoleIds(Authentication authentication) {
        Map<String, Object> details = extractDetails(authentication);
        if (details == null) {
            return new ArrayList<>();
        }
        Object roleIds = details.get("roleIds");
        if (roleIds instanceof List<?> list) {
            List<Long> result = new ArrayList<>();
            for (Object item : list) {
                Long roleId = convertToLong(item);
                if (roleId != null) {
                    result.add(roleId);
                }
            }
            return result;
        }
        return new ArrayList<>();
    }

    /**
     * 提取 Authentication 的 details Map。
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> extractDetails(Authentication authentication) {
        Object details = authentication.getDetails();
        if (details instanceof Map<?, ?> map) {
            return (Map<String, Object>) map;
        }
        return null;
    }

    /**
     * 将对象转换为 Long。
     */
    private Long convertToLong(Object value) {
        if (value instanceof Long l) return l;
        if (value instanceof Integer i) return i.longValue();
        if (value instanceof Number n) return n.longValue();
        return null;
    }
}
