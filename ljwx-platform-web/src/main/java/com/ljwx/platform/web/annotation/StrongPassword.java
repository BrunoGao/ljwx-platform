package com.ljwx.platform.web.annotation;

import com.ljwx.platform.web.validator.StrongPasswordValidator;
import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 密码复杂度校验注解。
 *
 * <p>规则：最少 8 位，且必须包含大写字母、小写字母、数字、特殊字符（{@code !@#$%^&*}）中至少 3 类。
 */
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = StrongPasswordValidator.class)
public @interface StrongPassword {

    String message() default "密码至少8位，且须包含大写字母、小写字母、数字、特殊字符(!@#$%^&*)中至少3类";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
