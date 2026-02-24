package com.ljwx.platform.web.filter;

import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import org.springframework.web.util.HtmlUtils;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

/**
 * XSS 防护请求包装器。
 *
 * <p>缓存请求体（支持多次读取），对 getParameter / getParameterValues / getHeader
 * 返回值调用 {@link HtmlUtils#htmlEscape} 转义 HTML 特殊字符。
 */
public class XssHttpServletRequestWrapper extends HttpServletRequestWrapper {

    private final byte[] cachedBody;

    public XssHttpServletRequestWrapper(HttpServletRequest request) throws IOException {
        super(request);
        cachedBody = request.getInputStream().readAllBytes();
    }

    @Override
    public String getParameter(String name) {
        String value = super.getParameter(name);
        return value != null ? HtmlUtils.htmlEscape(value) : null;
    }

    @Override
    public String[] getParameterValues(String name) {
        String[] values = super.getParameterValues(name);
        if (values == null) return null;
        String[] escaped = new String[values.length];
        for (int i = 0; i < values.length; i++) {
            escaped[i] = values[i] != null ? HtmlUtils.htmlEscape(values[i]) : null;
        }
        return escaped;
    }

    @Override
    public String getHeader(String name) {
        String value = super.getHeader(name);
        return value != null ? HtmlUtils.htmlEscape(value) : null;
    }

    @Override
    public ServletInputStream getInputStream() {
        ByteArrayInputStream bais = new ByteArrayInputStream(cachedBody);
        return new ServletInputStream() {
            @Override public boolean isFinished() { return bais.available() == 0; }
            @Override public boolean isReady() { return true; }
            @Override public void setReadListener(ReadListener listener) {}
            @Override public int read() { return bais.read(); }
        };
    }

    @Override
    public BufferedReader getReader() {
        return new BufferedReader(
                new InputStreamReader(new ByteArrayInputStream(cachedBody), StandardCharsets.UTF_8));
    }
}
