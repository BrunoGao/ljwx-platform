package com.ljwx.platform.core.security;

import com.fasterxml.jackson.annotation.JacksonAnnotationsInside;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 数据脱敏注解。
 * 标记在字段上，Jackson 序列化时自动脱敏。
 */
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@JacksonAnnotationsInside
@JsonSerialize(using = DataMaskSerializer.class)
public @interface DataMask {

    /**
     * 脱敏类型
     */
    MaskType type();

    /**
     * 自定义规则（CUSTOM 类型时使用）
     */
    String pattern() default "";

    /**
     * 解除脱敏权限
     */
    String unmaskPermission() default "system:data:unmask";
}
