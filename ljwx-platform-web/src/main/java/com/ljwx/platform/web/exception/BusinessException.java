package com.ljwx.platform.web.exception;

import com.ljwx.platform.core.result.ErrorCode;

/**
 * Business exception — carries an {@link ErrorCode} for precise error reporting.
 *
 * <p>Thrown from any service or facade layer to signal a known business error
 * (e.g., resource not found, token expired, tenant rejected). The
 * {@link com.ljwx.platform.web.advice.GlobalExceptionHandler} translates this
 * exception into the appropriate HTTP status code and {@code Result} body.
 *
 * <pre>{@code
 * // Usage example
 * throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND);
 * throw new BusinessException(ErrorCode.TOKEN_EXPIRED, "Access token has expired");
 * }</pre>
 */
public class BusinessException extends RuntimeException {

    private final ErrorCode errorCode;

    /**
     * Creates a BusinessException with SYSTEM_ERROR code and custom message.
     *
     * @param message custom message
     */
    public BusinessException(String message) {
        super(message);
        this.errorCode = ErrorCode.SYSTEM_ERROR;
    }

    /**
     * Creates a BusinessException with SYSTEM_ERROR code, custom message and cause.
     *
     * @param message custom message
     * @param cause root cause
     */
    public BusinessException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = ErrorCode.SYSTEM_ERROR;
    }

    /**
     * Creates a BusinessException using the default message from the given error code.
     *
     * @param errorCode the error code describing this error
     */
    public BusinessException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }

    /**
     * Creates a BusinessException with a custom message overriding the default.
     *
     * @param errorCode the error code describing this error
     * @param message   a more specific message for this occurrence
     */
    public BusinessException(ErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    /**
     * Creates a BusinessException using a raw HTTP-like code and custom message.
     *
     * <p>This keeps backward compatibility with historical call sites that
     * used {@code new BusinessException(400, "...")}.
     */
    public BusinessException(int code, String message) {
        super(message);
        this.errorCode = switch (code) {
            case 400 -> ErrorCode.PARAM_VALIDATION_FAILED;
            case 401 -> ErrorCode.TOKEN_INVALID;
            case 403 -> ErrorCode.PERMISSION_DENIED;
            case 404 -> ErrorCode.RESOURCE_NOT_FOUND;
            default -> ErrorCode.SYSTEM_ERROR;
        };
    }

    /**
     * Returns the {@link ErrorCode} associated with this exception.
     */
    public ErrorCode getErrorCode() {
        return errorCode;
    }
}
