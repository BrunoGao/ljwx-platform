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

    MENU_HAS_CHILDREN(400002, "菜单下存在子菜单，无法删除"),

    REPEAT_SUBMIT(409001, "重复提交，请稍后再试"),

    ACCOUNT_LOCKED(423001, "账号已锁定，请30分钟后重试"),

    DOMAIN_EXISTS(409002, "域名已存在"),
    INVALID_DOMAIN_FORMAT(400003, "域名格式不正确"),
    CANNOT_DELETE_PRIMARY_DOMAIN(400004, "无法删除主域名"),
    DOMAIN_NOT_FOUND(404002, "域名不存在"),
    DOMAIN_VERIFY_FAILED(400005, "域名验证失败"),

    SYSTEM_ERROR(500001, "系统内部错误");

    private final int code;
    private final String message;
}
