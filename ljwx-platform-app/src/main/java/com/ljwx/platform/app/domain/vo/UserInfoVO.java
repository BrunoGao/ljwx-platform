package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.util.List;

/**
 * 当前登录用户信息（嵌套在 LoginVO 中，也用于 /api/auth/me 响应）。
 */
@Data
public class UserInfoVO {

    private Long id;
    private String username;
    private String nickname;
    private String email;
    private String phone;
    private String avatar;
    /** 权限字符串列表，如 ["user:read", "user:write"] */
    private List<String> authorities;
    /** 角色编码列表，如 ["ADMIN"] */
    private List<String> roles;
    private Long tenantId;
}
