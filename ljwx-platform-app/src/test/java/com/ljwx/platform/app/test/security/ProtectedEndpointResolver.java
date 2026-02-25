package com.ljwx.platform.app.test.security;

import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.lang.reflect.Method;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * Finds a stable protected endpoint from Spring MVC mapping metadata.
 */
@Component
public class ProtectedEndpointResolver {

    private final RequestMappingHandlerMapping handlerMapping;

    public ProtectedEndpointResolver(RequestMappingHandlerMapping handlerMapping) {
        this.handlerMapping = handlerMapping;
    }

    public Optional<ResolvedEndpoint> findPreAuthorizeGetEndpoint() {
        List<ResolvedEndpoint> endpoints = handlerMapping.getHandlerMethods().entrySet().stream()
                .filter(e -> hasPreAuthorize(e.getValue().getMethod()))
                .filter(e -> e.getKey().getMethodsCondition().getMethods().contains(RequestMethod.GET))
                .flatMap(e -> e.getKey().getPatternValues().stream()
                        .map(path -> new ResolvedEndpoint(path, preAuthorizeValue(e.getValue().getMethod()).orElse(""))))
                .filter(e -> e.path().startsWith("/api"))
                .sorted(Comparator.comparing(ResolvedEndpoint::path))
                .toList();

        return endpoints.stream()
                .filter(e -> e.preAuthorize().contains("hasAuthority"))
                .findFirst()
                .or(() -> endpoints.stream().findFirst());
    }

    public boolean hasEndpointPath(String path) {
        return handlerMapping.getHandlerMethods().keySet().stream()
                .flatMap(info -> info.getPatternValues().stream())
                .anyMatch(path::equals);
    }

    private boolean hasPreAuthorize(Method method) {
        return preAuthorizeValue(method).isPresent();
    }

    private Optional<String> preAuthorizeValue(Method method) {
        PreAuthorize anno = AnnotatedElementUtils.findMergedAnnotation(method, PreAuthorize.class);
        if (anno == null || anno.value() == null || anno.value().isBlank()) {
            return Optional.empty();
        }
        return Optional.of(anno.value());
    }

    public record ResolvedEndpoint(String path, String preAuthorize) {
    }
}
