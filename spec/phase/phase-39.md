---
phase: 39
title: "数据脱敏 (Data Masking)"
targets:
  backend: true
  frontend: false
depends_on: [38]
bundle_with: []
scope:
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/security/DataMask.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/security/DataMaskSerializer.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/security/MaskType.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/security/DataMaskAspect.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/UserVO.java"
---
# Phase 39 — 数据脱敏

| 项目 | 值 |
|-----|---|
| Phase | 39 |
| 模块 | ljwx-platform-core (后端) |
| Feature | L0-D04-F03 |
| 前置依赖 | Phase 38 (租户品牌配置) |
| 测试契约 | `spec/tests/phase-39-data-mask.tests.yml` |
| 优先级 | 🔴 **P0 - 必须在开放平台前完成** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §数据脱敏
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 开放 API 可能泄露手机号、身份证、邮箱等敏感数据。

**解决方案**: 实现基于注解的数据脱敏框架:
1. @DataMask 注解标记敏感字段
2. Jackson 序列化时自动脱敏
3. 支持多种脱敏规则
4. 权限控制（system:data:unmask）

---

## 脱敏规则

### MaskType 枚举

| 类型 | 规则 | 示例 |
|------|------|------|
| **PHONE** | 保留前 3 后 4 | 138****5678 |
| **ID_CARD** | 保留前 6 后 4 | 110101****1234 |
| **EMAIL** | 保留前 2 和域名 | ab***@example.com |
| **NAME** | 保留姓,名脱敏 | 张** |
| **BANK_CARD** | 保留后 4 | **** **** **** 1234 |
| **ADDRESS** | 保留省市,详细地址脱敏 | 北京市朝阳区**** |
| **CUSTOM** | 自定义规则 | 由 pattern 指定 |

---

## 核心组件契约

### @DataMask 注解

```java
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@JacksonAnnotationsInside
@JsonSerialize(using = DataMaskSerializer.class)
public @interface DataMask {
    MaskType type();                    // 脱敏类型
    String pattern() default "";        // 自定义规则（CUSTOM 类型）
    String unmaskPermission() default "system:data:unmask";  // 解除脱敏权限
}
```

### DataMaskSerializer

```java
public class DataMaskSerializer extends JsonSerializer<String> {

    @Override
    public void serialize(String value, JsonGenerator gen, SerializerProvider serializers) {
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
        DataMask annotation = getAnnotation(gen);
        if (annotation == null) {
            gen.writeString(value);
            return;
        }

        // 脱敏
        String masked = mask(value, annotation.type(), annotation.pattern());
        gen.writeString(masked);
    }

    private boolean hasUnmaskPermission() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return false;
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("system:data:unmask"));
    }
}
```

---

## 使用示例

### UserVO

```java
@Data
public class UserVO {
    private Long id;
    private String username;

    @DataMask(type = MaskType.PHONE)
    private String mobile;

    @DataMask(type = MaskType.EMAIL)
    private String email;

    @DataMask(type = MaskType.ID_CARD)
    private String idCard;

    @DataMask(type = MaskType.NAME)
    private String realName;

    private LocalDateTime createdTime;
}
```

### 响应示例

**无 unmask 权限**:
```json
{
  "id": 1,
  "username": "zhangsan",
  "mobile": "138****5678",
  "email": "zh***@example.com",
  "idCard": "110101****1234",
  "realName": "张**"
}
```

**有 unmask 权限**:
```json
{
  "id": 1,
  "username": "zhangsan",
  "mobile": "13812345678",
  "email": "zhangsan@example.com",
  "idCard": "110101199001011234",
  "realName": "张三"
}
```

---

## 业务规则

> 格式：BL-39-{序号}：[条件] → [动作] → [结果/异常]

- **BL-39-01**：字段标记 @DataMask → Jackson 序列化时脱敏 → 返回脱敏值
- **BL-39-02**：用户有 `system:data:unmask` 权限 → 跳过脱敏 → 返回原始值
- **BL-39-03**：手机号脱敏（PHONE）→ 保留前 3 后 4 → `138****5678`
- **BL-39-04**：身份证脱敏 → 保留前 6 后 4 → `110101****1234`
- **BL-39-05**：邮箱脱敏 → 保留前 2 和域名 → `ab***@example.com`
- **BL-39-06**：姓名脱敏 → 保留姓,名脱敏 → `张**`
- **BL-39-07**：银行卡脱敏 → 保留后 4 → `**** **** **** 1234`
- **BL-39-08**：地址脱敏 → 保留省市 → `北京市朝阳区****`
- **BL-39-09**：自定义规则 → 使用 pattern 正则 → 按规则脱敏

---

## 权限配置

### 权限字符串

- `system:data:unmask` - 解除数据脱敏

### 角色配置

| 角色 | 是否有 unmask 权限 |
|------|-------------------|
| 超级管理员 | ✅ |
| 租户管理员 | ✅ |
| 普通用户 | ❌ |
| 开放 API | ❌ |

---

## 测试用���（摘要）

详细用例见 **`spec/tests/phase-39-data-mask.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-39-01 | 手机号脱敏 | P0 |
| TC-39-02 | 身份证脱敏 | P0 |
| TC-39-03 | 邮箱脱敏 | P0 |
| TC-39-04 | 姓名脱敏 | P0 |
| TC-39-05 | 银行卡脱敏 | P0 |
| TC-39-06 | 有 unmask 权限返回原始值 | P0 |
| TC-39-07 | 无 unmask 权限返回脱敏值 | P0 |

---

## 验收条件

- **AC-01**：@DataMask 注解正常工作
- **AC-02**：Jackson 序列化时自动脱敏
- **AC-03**：有 unmask 权限返回原始值
- **AC-04**：无 unmask 权限返回脱敏值
- **AC-05**：所有脱敏规则正确
- **AC-06**：开放 API 默认脱敏
- **AC-07**：编译通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 脱敏时机：Jackson 序列化时,不修改数据库
- 权限控制：`system:data:unmask` 权限可解除脱敏
- 开放 API：默认脱敏,不授予 unmask 权限
- 禁止：在数据库层脱敏,影响查询性能

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-39-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-39-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-39-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-39-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-39-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-39-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-39-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-39-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-39-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-39-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
