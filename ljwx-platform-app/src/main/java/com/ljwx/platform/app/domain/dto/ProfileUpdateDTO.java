package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

/**
 * 个人信息修改 DTO（昵称、邮箱、手机）。
 * 不含租户字段。
 */
public class ProfileUpdateDTO {

    @Size(max = 50)
    private String nickname;

    @Email
    @Size(max = 100)
    private String email;

    @Size(max = 20)
    private String phone;

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
}
