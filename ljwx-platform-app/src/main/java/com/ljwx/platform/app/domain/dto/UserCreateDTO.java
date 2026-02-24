package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

/**
 * 创建用户 DTO（租户由后端自动注入）。
 */
@Data
public class UserCreateDTO {

    @NotBlank(message = "用户名不能为空")
    private String username;

    @NotBlank(message = "密码不能为空")
    private String password;

    @NotBlank(message = "昵称不能为空")
    private String nickname;

    private String email;

    private String phone;

    /** 角色 ID 列表 */
    private List<Long> roleIds;
}
