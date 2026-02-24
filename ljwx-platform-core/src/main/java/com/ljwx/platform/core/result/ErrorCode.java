package com.ljwx.platform.core.result;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 错误码枚举 — 对应 spec/03-api.md §错误码
 */
@Getter
@RequiredArgsConstructor
public enum ErrorCode {

    SUCCESS(200, "success"),

    PARAM_VALIDATION_FAILED(400001, "参数校验失败"),

    TOKEN_INVALID(401001, "Token 无效"),
    TOKEN_EXPIRED(401002, "Token 过期"),

    TENANT_REJECTED(403001, "租户拒绝"),
    PERMISSION_DENIED(403002, "权限不足"),

    RESOURCE_NOT_FOUND(404001, "资源不存在"),

    REPEAT_SUBMIT(409001, "重复提交，请稍后再试"),

    ACCOUNT_LOCKED(423001, "账号已锁定，请30分钟后重试"),

    SYSTEM_ERROR(500001, "系统内部错误");

    private final int code;
    private final String message;
}
