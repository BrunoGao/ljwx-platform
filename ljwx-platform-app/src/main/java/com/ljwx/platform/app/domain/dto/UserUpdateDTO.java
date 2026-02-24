package com.ljwx.platform.app.domain.dto;

import lombok.Data;

import java.util.List;

/**
 * 更新用户 DTO（不含 tenantId，由 TenantLineInterceptor 自动注入）。
 */
@Data
public class UserUpdateDTO {

    private String nickname;
    private String email;
    private String phone;
    /** 状态：1-启用，0-禁用 */
    private Integer status;
    /** 角色 ID 列表（提供时全量替换） */
    private List<Long> roleIds;
    /** 乐观锁版本号（可选，未提供时跳过版本校验） */
    private Integer version;
}
