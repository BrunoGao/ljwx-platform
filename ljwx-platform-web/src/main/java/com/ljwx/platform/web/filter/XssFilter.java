package com.ljwx.platform.web.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * XSS 过滤器。
 *
 * <p>对所有 {@code /api/**} 路径（排除文件上传端点）将请求包装为
 * {@link XssHttpServletRequestWrapper}，对参数和请求头进行 HTML 转义。
 *
 * <p>注册为 order=1（最高优先级），在 SecurityConfig 中通过
 * {@code FilterRegistrationBean} 注册。
 */
@Component
public class XssFilter implements Filter {

    private static final String UPLOAD_PATH = "/api/v1/files/upload";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String uri = httpRequest.getRequestURI();

        if (uri.startsWith("/api/") && !uri.equals(UPLOAD_PATH)) {
            chain.doFilter(new XssHttpServletRequestWrapper(httpRequest), response);
        } else {
            chain.doFilter(request, response);
        }
    }
}
