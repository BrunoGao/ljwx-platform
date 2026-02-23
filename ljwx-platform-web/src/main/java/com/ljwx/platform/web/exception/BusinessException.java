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
     * Returns the {@link ErrorCode} associated with this exception.
     */
    public ErrorCode getErrorCode() {
        return errorCode;
    }
}
