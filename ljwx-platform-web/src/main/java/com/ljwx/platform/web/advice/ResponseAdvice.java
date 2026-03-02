package com.ljwx.platform.web.advice;

import com.ljwx.platform.core.result.Result;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

/**
 * Response body advice that ensures every API response is wrapped in the
 * platform-standard {@link Result} envelope.
 *
 * <p>Controllers that already return {@code Result<T>} are passed through
 * unchanged (no double-wrapping). Raw data objects are wrapped with
 * {@link Result#ok(Object)}.
 *
 * <p>{@code String} return types are explicitly excluded from this advice
 * to avoid {@link ClassCastException} caused by the String message converter
 * being selected before the advice can serialize the wrapper.
 *
 * <pre>{@code
 * // Controller returns raw List<UserVO> → advice wraps it:
 * // { "code": 200, "message": "success", "data": [...], "traceId": "..." }
 *
 * // Controller returns Result<PageResult<UserVO>> → advice passes through:
 * // { "code": 200, "message": "success", "data": { "list": [...], "total": 5 }, ... }
 * }</pre>
 */
@RestControllerAdvice
public class ResponseAdvice implements ResponseBodyAdvice<Object> {

    /**
     * Applies this advice to all JSON responses except {@code String} return types
     * and SpringDoc/Swagger endpoints.
     *
     * <p>{@code String} types are excluded to avoid conflicts with the
     * {@code StringHttpMessageConverter}: when a controller returns {@code String},
     * Jackson is not selected, so wrapping it here would cause a conversion error.
     *
     * <p>SpringDoc endpoints ({@code /v3/api-docs/**}, {@code /swagger-ui/**})
     * are excluded to prevent wrapping OpenAPI documentation in {@link Result}.
     */
    @Override
    public boolean supports(MethodParameter returnType,
                            Class<? extends HttpMessageConverter<?>> converterType) {
        // Exclude String types to avoid StringHttpMessageConverter conflicts
        if (String.class.equals(returnType.getParameterType())) {
            return false;
        }

        // Exclude SpringDoc/Swagger endpoints
        String declaringClassName = returnType.getDeclaringClass().getName();
        if (declaringClassName.startsWith("org.springdoc") ||
            declaringClassName.startsWith("springfox.documentation")) {
            return false;
        }

        return true;
    }

    /**
     * Wraps the response body in {@link Result#ok(Object)} if it is not already
     * a {@link Result} instance.
     *
     * <ul>
     *   <li>Already a {@code Result} → returned as-is (prevents double-wrapping).</li>
     *   <li>{@code null} body → returns {@link Result#ok()} with no data.</li>
     *   <li>Any other object → returns {@link Result#ok(Object)} with data set.</li>
     * </ul>
     */
    @Override
    public Object beforeBodyWrite(Object body,
                                  MethodParameter returnType,
                                  MediaType selectedContentType,
                                  Class<? extends HttpMessageConverter<?>> selectedConverterType,
                                  ServerHttpRequest request,
                                  ServerHttpResponse response) {
        // Already a Result — pass through to avoid double-wrapping
        if (body instanceof Result<?>) {
            return body;
        }
        // Null body — return ok with no data payload
        if (body == null) {
            return Result.ok();
        }
        // Raw data — wrap in standard Result envelope
        return Result.ok(body);
    }
}
