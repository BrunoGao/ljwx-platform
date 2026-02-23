package com.ljwx.platform.web.advice;

import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.Result;
import com.ljwx.platform.web.exception.BusinessException;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.BindException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.stream.Collectors;

/**
 * Global exception handler for the LJWX platform.
 *
 * <p>Maps every {@link ErrorCode} variant to a corresponding HTTP status and
 * {@link Result} response body:
 *
 * <ul>
 *   <li>{@code 400001} PARAM_VALIDATION_FAILED — validation / binding / parse errors</li>
 *   <li>{@code 401001} TOKEN_INVALID — {@link AuthenticationException} or
 *       {@link BusinessException}({@link ErrorCode#TOKEN_INVALID})</li>
 *   <li>{@code 401002} TOKEN_EXPIRED — {@link BusinessException}({@link ErrorCode#TOKEN_EXPIRED})</li>
 *   <li>{@code 403001} TENANT_REJECTED — {@link BusinessException}({@link ErrorCode#TENANT_REJECTED})</li>
 *   <li>{@code 403002} PERMISSION_DENIED — {@link AccessDeniedException}</li>
 *   <li>{@code 404001} RESOURCE_NOT_FOUND — no-handler / no-resource exceptions</li>
 *   <li>{@code 500001} SYSTEM_ERROR — unhandled {@link Exception}</li>
 * </ul>
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    // ─── Business exceptions — wraps any ErrorCode ─────────────────────────────

    /**
     * Handles {@link BusinessException}, which carries any {@link ErrorCode}.
     * Covers TOKEN_EXPIRED (401002) and TENANT_REJECTED (403001) that are not
     * mapped to Spring Security exceptions.
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Result<?>> handleBusinessException(BusinessException ex) {
        log.warn("Business exception: code={}, message={}", ex.getErrorCode().getCode(), ex.getMessage());
        return ResponseEntity
                .status(httpStatusFor(ex.getErrorCode()))
                .body(Result.fail(ex.getErrorCode().getCode(), ex.getMessage()));
    }

    // ─── Validation (400001) ────────────────────────────────────────────────────

    /**
     * Handles {@link MethodArgumentNotValidException} — {@code @RequestBody @Valid} failures.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Result<?>> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .collect(Collectors.joining(", "));
        log.debug("Validation failed: {}", message);
        return ResponseEntity
                .badRequest()
                .body(Result.fail(ErrorCode.PARAM_VALIDATION_FAILED.getCode(), message));
    }

    /**
     * Handles {@link BindException} — query-param / form binding failures.
     */
    @ExceptionHandler(BindException.class)
    public ResponseEntity<Result<?>> handleBind(BindException ex) {
        String message = ex.getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .collect(Collectors.joining(", "));
        log.debug("Bind exception: {}", message);
        return ResponseEntity
                .badRequest()
                .body(Result.fail(ErrorCode.PARAM_VALIDATION_FAILED.getCode(), message));
    }

    /**
     * Handles {@link ConstraintViolationException} — {@code @Validated} on method params.
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Result<?>> handleConstraintViolation(ConstraintViolationException ex) {
        String message = ex.getConstraintViolations().stream()
                .map(cv -> cv.getPropertyPath() + ": " + cv.getMessage())
                .collect(Collectors.joining(", "));
        log.debug("Constraint violation: {}", message);
        return ResponseEntity
                .badRequest()
                .body(Result.fail(ErrorCode.PARAM_VALIDATION_FAILED.getCode(), message));
    }

    /**
     * Handles {@link HttpMessageNotReadableException} — malformed JSON request body.
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Result<?>> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        log.debug("HTTP message not readable: {}", ex.getMessage());
        return ResponseEntity
                .badRequest()
                .body(Result.fail(ErrorCode.PARAM_VALIDATION_FAILED));
    }

    /**
     * Handles {@link MissingServletRequestParameterException} — missing required query param.
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Result<?>> handleMissingServletRequestParameter(
            MissingServletRequestParameterException ex) {
        String message = "Missing required parameter: " + ex.getParameterName();
        log.debug("Missing request parameter: {}", ex.getParameterName());
        return ResponseEntity
                .badRequest()
                .body(Result.fail(ErrorCode.PARAM_VALIDATION_FAILED.getCode(), message));
    }

    // ─── Authentication (401001) ────────────────────────────────────────────────

    /**
     * Handles {@link AuthenticationException} — unauthenticated access (TOKEN_INVALID).
     *
     * <p>Note: JWT validation failures inside {@code JwtAuthenticationFilter} clear the
     * security context and let the request proceed as anonymous. Spring Security will
     * invoke {@code AuthenticationEntryPoint} for endpoints that require authentication,
     * which in turn re-throws an {@link AuthenticationException} caught here.
     */
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<Result<?>> handleAuthentication(AuthenticationException ex) {
        log.warn("Authentication exception: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(Result.fail(ErrorCode.TOKEN_INVALID));
    }

    // ─── Access denied (403002) ─────────────────────────────────────────────────

    /**
     * Handles {@link AccessDeniedException} — {@code @PreAuthorize} failures (PERMISSION_DENIED).
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Result<?>> handleAccessDenied(AccessDeniedException ex) {
        log.warn("Access denied: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(Result.fail(ErrorCode.PERMISSION_DENIED));
    }

    // ─── Not found (404001) ─────────────────────────────────────────────────────

    /**
     * Handles {@link NoHandlerFoundException} and {@link NoResourceFoundException}
     * — unmapped request paths.
     */
    @ExceptionHandler({NoHandlerFoundException.class, NoResourceFoundException.class})
    public ResponseEntity<Result<?>> handleNotFound(Exception ex) {
        log.debug("Resource not found: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(Result.fail(ErrorCode.RESOURCE_NOT_FOUND));
    }

    // ─── Fallback (500001) ──────────────────────────────────────────────────────

    /**
     * Catch-all handler — maps any unhandled {@link Exception} to SYSTEM_ERROR (500001).
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Result<?>> handleGeneric(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Result.fail(ErrorCode.SYSTEM_ERROR));
    }

    // ─── Helpers ────────────────────────────────────────────────────────────────

    /**
     * Derives the appropriate {@link HttpStatus} from an {@link ErrorCode} based on
     * the numeric prefix (400xxx → 400, 401xxx → 401, 403xxx → 403, 404xxx → 404,
     * 500xxx → 500).
     */
    private HttpStatus httpStatusFor(ErrorCode errorCode) {
        int code = errorCode.getCode();
        if (code >= 400000 && code < 401000) return HttpStatus.BAD_REQUEST;
        if (code >= 401000 && code < 402000) return HttpStatus.UNAUTHORIZED;
        if (code >= 403000 && code < 404000) return HttpStatus.FORBIDDEN;
        if (code >= 404000 && code < 405000) return HttpStatus.NOT_FOUND;
        return HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
