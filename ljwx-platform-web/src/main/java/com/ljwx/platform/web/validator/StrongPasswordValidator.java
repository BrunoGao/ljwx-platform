package com.ljwx.platform.web.validator;

import com.ljwx.platform.web.annotation.StrongPassword;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

/**
 * {@link StrongPassword} 约束校验器。
 *
 * <p>规则：最少 8 位，且必须包含大写字母、小写字母、数字、特殊字符（{@code !@#$%^&*}）中至少 3 类。
 */
public class StrongPasswordValidator implements ConstraintValidator<StrongPassword, String> {

    private static final String SPECIAL_CHARS = "!@#$%^&*";

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null || value.length() < 8) {
            return false;
        }

        int categories = 0;
        if (value.chars().anyMatch(Character::isUpperCase)) categories++;
        if (value.chars().anyMatch(Character::isLowerCase)) categories++;
        if (value.chars().anyMatch(Character::isDigit)) categories++;
        if (value.chars().anyMatch(c -> SPECIAL_CHARS.indexOf(c) >= 0)) categories++;

        return categories >= 3;
    }
}
