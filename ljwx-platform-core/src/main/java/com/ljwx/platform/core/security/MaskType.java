package com.ljwx.platform.core.security;

/**
 * 数据脱敏类型枚举。
 */
public enum MaskType {

    /**
     * 手机号脱敏：保留前 3 后 4，如 138****5678
     */
    PHONE,

    /**
     * 身份证脱敏：保留前 6 后 4，如 110101****1234
     */
    ID_CARD,

    /**
     * 邮箱脱敏：保留前 2 和域名，如 ab***@example.com
     */
    EMAIL,

    /**
     * 姓名脱敏：保留姓，名脱敏，如 张**
     */
    NAME,

    /**
     * 银行卡脱敏：保留后 4，如 **** **** **** 1234
     */
    BANK_CARD,

    /**
     * 地址脱敏：保留省市，详细地址脱敏，如 北京市朝阳区****
     */
    ADDRESS,

    /**
     * 自定义规则：由 pattern 指定
     */
    CUSTOM
}
