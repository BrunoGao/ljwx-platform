package com.ljwx.platform.core.security;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.BeanProperty;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.ContextualSerializer;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 数据脱敏序列化器。
 * Jackson 序列化时自动脱敏敏感字段。
 */
public class DataMaskSerializer extends JsonSerializer<String> implements ContextualSerializer {

    private DataMask annotation;

    public DataMaskSerializer() {
    }

    public DataMaskSerializer(DataMask annotation) {
        this.annotation = annotation;
    }

    @Override
    public void serialize(String value, JsonGenerator gen, SerializerProvider serializers) throws IOException {
        if (value == null) {
            gen.writeNull();
            return;
        }

        // 检查权限
        if (hasUnmaskPermission()) {
            gen.writeString(value);
            return;
        }

        // 获取注解
        if (annotation == null) {
            gen.writeString(value);
            return;
        }

        // 脱敏
        String masked = mask(value, annotation.type(), annotation.pattern());
        gen.writeString(masked);
    }

    @Override
    public JsonSerializer<?> createContextual(SerializerProvider prov, BeanProperty property) {
        if (property != null) {
            DataMask ann = property.getAnnotation(DataMask.class);
            if (ann != null) {
                return new DataMaskSerializer(ann);
            }
        }
        return this;
    }

    /**
     * 检查是否有解除脱敏权限
     */
    private boolean hasUnmaskPermission() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            return false;
        }
        String permission = annotation != null ? annotation.unmaskPermission() : "system:data:unmask";
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals(permission));
    }

    /**
     * 脱敏处理
     */
    private String mask(String value, MaskType type, String pattern) {
        if (value == null || value.isEmpty()) {
            return value;
        }

        return switch (type) {
            case PHONE -> maskPhone(value);
            case ID_CARD -> maskIdCard(value);
            case EMAIL -> maskEmail(value);
            case NAME -> maskName(value);
            case BANK_CARD -> maskBankCard(value);
            case ADDRESS -> maskAddress(value);
            case CUSTOM -> maskCustom(value, pattern);
        };
    }

    /**
     * 手机号脱敏：保留前 3 后 4
     */
    private String maskPhone(String phone) {
        if (phone.length() < 7) {
            return "***";
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    /**
     * 身份证脱敏：保留前 6 后 4
     */
    private String maskIdCard(String idCard) {
        if (idCard.length() < 10) {
            return "******";
        }
        return idCard.substring(0, 6) + "****" + idCard.substring(idCard.length() - 4);
    }

    /**
     * 邮箱脱敏：保留前 2 和域名
     */
    private String maskEmail(String email) {
        int atIndex = email.indexOf('@');
        if (atIndex <= 0) {
            return "***";
        }
        String localPart = email.substring(0, atIndex);
        String domain = email.substring(atIndex);

        if (localPart.length() <= 2) {
            return localPart.charAt(0) + "***" + domain;
        }
        return localPart.substring(0, 2) + "***" + domain;
    }

    /**
     * 姓名脱敏：保留姓，名脱敏
     */
    private String maskName(String name) {
        if (name.length() <= 1) {
            return name;
        }
        return name.charAt(0) + "**";
    }

    /**
     * 银行卡脱敏：保留后 4
     */
    private String maskBankCard(String bankCard) {
        if (bankCard.length() < 4) {
            return "****";
        }
        String last4 = bankCard.substring(bankCard.length() - 4);
        return "**** **** **** " + last4;
    }

    /**
     * 地址脱敏：保留省市
     */
    private String maskAddress(String address) {
        // 简单实现：保留前 6 个字符（通常是省市）
        if (address.length() <= 6) {
            return address;
        }
        return address.substring(0, 6) + "****";
    }

    /**
     * 自定义规则脱敏
     */
    private String maskCustom(String value, String pattern) {
        if (pattern == null || pattern.isEmpty()) {
            return "***";
        }
        try {
            Pattern p = Pattern.compile(pattern);
            Matcher m = p.matcher(value);
            if (m.find()) {
                return m.replaceAll("***");
            }
        } catch (Exception e) {
            // 正则错误，返回默认脱敏
        }
        return "***";
    }
}
