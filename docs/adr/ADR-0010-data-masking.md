# ADR-0010: 脱敏在序列化层实现，解脱敏受权限控制

## Status
Accepted

## Context
开放平台/导出/报表等输出路径多,分散处理容易遗漏。

在多租户 SaaS 平台中,敏感数据脱敏是必须的:
- 手机号、身份证号、银行卡号等敏感信息
- 不同角色对敏感数据的访问权限不同
- 输出路径多: REST API、导出、报表、日志、Webhook

### 常见方案对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| 业务层脱敏 | 灵活 | 分散处理,容易遗漏 |
| 数据库视图 | 统一 | 无法根据权限动态脱敏 |
| 序列化层脱敏 | 统一,可控 | 需要全局扫描敏感字段 |

## Decision
统一用 Jackson 注解 `@DataMask` 在序列化层脱敏；持有 `system:data:unmask` 的主体可输出原文；存储层敏感字段另用 AES 加密（可选 P1）。

### 实现方案

#### 1. 脱敏注解
```java
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface DataMask {
    MaskType type();
    String unmaskPermission() default "system:data:unmask";
}

public enum MaskType {
    PHONE,       // 138****5678
    ID_CARD,     // 110***********1234
    BANK_CARD,   // 6222 **** **** 1234
    EMAIL,       // a***@example.com
    NAME,        // 张*
    ADDRESS      // 北京市朝阳区***
}
```

#### 2. 序列化拦截
```java
public class DataMaskSerializer extends JsonSerializer<String> {
    @Override
    public void serialize(String value, JsonGenerator gen, SerializerProvider provider) {
        DataMask annotation = getAnnotation(gen);
        if (annotation == null) {
            gen.writeString(value);
            return;
        }

        // 检查权限
        if (hasPermission(annotation.unmaskPermission())) {
            gen.writeString(value);  // 输出原文
        } else {
            gen.writeString(mask(value, annotation.type()));  // 脱敏
        }
    }
}
```

#### 3. 使用示例
```java
@Data
public class UserDTO {
    private Long id;
    private String username;

    @DataMask(type = MaskType.PHONE)
    private String phone;

    @DataMask(type = MaskType.ID_CARD)
    private String idCard;

    @DataMask(type = MaskType.EMAIL)
    private String email;
}
```

#### 4. 权限控制
```sql
-- 插入解脱敏权限
INSERT INTO sys_permission (permission_code, permission_name, ...)
VALUES ('system:data:unmask', '数据解脱敏', ...);

-- 授予超级管理员
INSERT INTO sys_role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM sys_role r, sys_permission p
WHERE r.role_code = 'SUPER_ADMIN'
  AND p.permission_code = 'system:data:unmask';
```

### 覆盖路径
1. **REST API**: Jackson 序列化自动脱敏
2. **导出**: 使用相同的 DTO 和序列化器
3. **报表**: 使用相同的 DTO 和序列化器
4. **日志**: 敏感字段不输出到日志 (使用 `@JsonIgnore`)
5. **Webhook**: 使用相同的 DTO 和序列化器

## Consequences

### 正面影响
- 统一的脱敏策略,避免遗漏
- 基于权限的动态脱敏,灵活可控
- 所有输出路径自动脱敏,无需额外处理

### 负面影响
- 需要全局扫描敏感字段标注
- 需要针对导出/报表也复用同一序列化/映射策略并写测试防绕过
- 性能影响 (每次序列化都需要检查权限)

### 实施要点

#### 1. 敏感字段扫描
- 扫描所有 DTO 类,标注敏感字段
- 建立敏感字段清单,定期审查

#### 2. 测试覆盖
- 单元测试: 验证脱敏逻辑
- 集成测试: 验证所有输出路径 (REST/导出/报表)
- 安全测试: 验证无权限用户无法获取原文

#### 3. 性能优化
- 缓存权限判定结果 (请求级别)
- 使用 ThreadLocal 存储当前用户权限

#### 4. 存储层加密 (可选 P1)
- 敏感字段在数据库中使用 AES 加密
- 应用层自动加解密
- 密钥管理: 使用 KMS 或配置中心

## References
- Phase 39: 数据脱敏
- spec/phase/phase-39.md
