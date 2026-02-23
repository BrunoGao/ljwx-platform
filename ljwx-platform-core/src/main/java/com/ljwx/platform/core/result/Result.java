package com.ljwx.platform.core.result;

import lombok.Data;

import java.io.Serializable;
import java.util.UUID;

/**
 * 统一响应体 — 对应 spec/03-api.md §统一响应
 *
 * <pre>
 * {
 *   "code":    200,
 *   "message": "success",
 *   "data":    {},
 *   "traceId": "uuid"
 * }
 * </pre>
 */
@Data
public class Result<T> implements Serializable {

    private int code;
    private String message;
    private T data;
    private String traceId;

    private Result() {
    }

    // ── Factory methods ──────────────────────────────────────

    public static <T> Result<T> ok() {
        return ok(null);
    }

    public static <T> Result<T> ok(T data) {
        Result<T> result = new Result<>();
        result.setCode(ErrorCode.SUCCESS.getCode());
        result.setMessage(ErrorCode.SUCCESS.getMessage());
        result.setData(data);
        result.setTraceId(UUID.randomUUID().toString());
        return result;
    }

    public static <T> Result<T> fail(ErrorCode errorCode) {
        Result<T> result = new Result<>();
        result.setCode(errorCode.getCode());
        result.setMessage(errorCode.getMessage());
        result.setTraceId(UUID.randomUUID().toString());
        return result;
    }

    public static <T> Result<T> fail(int code, String message) {
        Result<T> result = new Result<>();
        result.setCode(code);
        result.setMessage(message);
        result.setTraceId(UUID.randomUUID().toString());
        return result;
    }
}
