package com.ljwx.platform.app.test.security;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.http.HttpMethod;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.lang.reflect.Method;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Discovers protocol-contract candidates from Spring MVC mappings.
 */
@Component
public class ProtocolEndpointResolver {

    private static final Set<String> PERMIT_ALL_PATHS = Set.of(
            "/api/auth/login",
            "/api/auth/refresh"
    );

    private final RequestMappingHandlerMapping handlerMapping;

    public ProtocolEndpointResolver(
            @Qualifier("requestMappingHandlerMapping") RequestMappingHandlerMapping handlerMapping
    ) {
        this.handlerMapping = handlerMapping;
    }

    public List<ProtocolEndpoint> protectedGetEndpoints() {
        return handlerMapping.getHandlerMethods().entrySet().stream()
                .flatMap(entry -> flattenGetMappings(entry.getKey(), entry.getValue()).stream())
                .filter(this::isProtected)
                .filter(e -> e.path().startsWith("/api"))
                .filter(e -> !e.path().contains("/*"))
                .sorted(Comparator.comparing(ProtocolEndpoint::path))
                .toList();
    }

    private List<ProtocolEndpoint> flattenGetMappings(RequestMappingInfo info, HandlerMethod handler) {
        Set<RequestMethod> methods = info.getMethodsCondition().getMethods();
        if (!methods.isEmpty() && !methods.contains(RequestMethod.GET)) {
            return List.of();
        }

        String preAuthorize = preAuthorizeValue(handler.getMethod());
        if (preAuthorize.isBlank()) {
            preAuthorize = preAuthorizeValue(handler.getBeanType());
        }

        final String pre = preAuthorize;
        return info.getPatternValues().stream()
                .map(this::normalizePath)
                .map(path -> new ProtocolEndpoint(
                        HttpMethod.GET,
                        path,
                        pre,
                        hasAuthorityExpression(pre)
                ))
                .toList();
    }

    private boolean isProtected(ProtocolEndpoint endpoint) {
        if (PERMIT_ALL_PATHS.contains(endpoint.path())) {
            return false;
        }
        if (endpoint.preAuthorize().contains("permitAll()")) {
            return false;
        }
        return true;
    }

    private boolean hasAuthorityExpression(String expression) {
        return expression != null && expression.contains("hasAuthority(");
    }

    private String normalizePath(String raw) {
        Pattern varPattern = Pattern.compile("\\{[^/]+}");
        Matcher matcher = varPattern.matcher(raw);
        return matcher.replaceAll("1");
    }

    private String preAuthorizeValue(Method method) {
        PreAuthorize anno = AnnotatedElementUtils.findMergedAnnotation(method, PreAuthorize.class);
        return anno == null || anno.value() == null ? "" : anno.value();
    }

    private String preAuthorizeValue(Class<?> beanType) {
        PreAuthorize anno = AnnotatedElementUtils.findMergedAnnotation(beanType, PreAuthorize.class);
        return anno == null || anno.value() == null ? "" : anno.value();
    }

    public record ProtocolEndpoint(
            HttpMethod method,
            String path,
            String preAuthorize,
            boolean hasAuthority
    ) {
    }
}
