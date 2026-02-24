package com.ljwx.platform.web.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 接口幂等注解。
 *
 * <p>标注在 Controller 方法上，{@link com.ljwx.platform.web.interceptor.IdempotentInterceptor}
 * 会在幂等窗口内拦截重复请求并返回 {@code REPEAT_SUBMIT} 错误码。
 *
 * <p>幂等键 = MD5(userId + requestURI + requestBody 前 512 字节)。
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Idempotent {

    /** 幂等窗口（秒），默认 10 秒。 */
    int expireSeconds() default 10;
}
