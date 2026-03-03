package com.ljwx.platform.core.exception;

import com.ljwx.platform.core.result.ErrorCode;

/**
 * Backward-compatible business exception.
 *
 * <p>Some newly added app services still import the historical
 * {@code com.ljwx.platform.core.exception.BusinessException} package path.
 * This class preserves that API surface while carrying {@link ErrorCode}.
 */
public class BusinessException extends RuntimeException {

    private final ErrorCode errorCode;

    /**
     * Builds an exception with a plain message and SYSTEM_ERROR fallback code.
     *
     * @param message business error message
     */
    public BusinessException(String message) {
        super(message);
        this.errorCode = ErrorCode.SYSTEM_ERROR;
    }

    /**
     * Builds an exception with a plain message, cause and SYSTEM_ERROR fallback code.
     *
     * @param message business error message
     * @param cause root cause
     */
    public BusinessException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = ErrorCode.SYSTEM_ERROR;
    }

    /**
     * Builds an exception using the default message from the given error code.
     *
     * @param errorCode error code
     */
    public BusinessException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }

    /**
     * Builds an exception with explicit code and custom message.
     *
     * @param errorCode error code
     * @param message custom message
     */
    public BusinessException(ErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    /**
     * Builds an exception from a raw HTTP-like code and message.
     *
     * @param code raw code (e.g. 400/404/500)
     * @param message custom message
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

    public ErrorCode getErrorCode() {
        return errorCode;
    }
}
