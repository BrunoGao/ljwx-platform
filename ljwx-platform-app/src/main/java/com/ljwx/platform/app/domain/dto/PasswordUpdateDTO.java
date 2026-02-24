package com.ljwx.platform.app.domain.dto;

import com.ljwx.platform.web.annotation.StrongPassword;
import jakarta.validation.constraints.NotBlank;

/**
 * 修改密码 DTO。
 * 不含租户字段。密码字段日志脱敏为 ***。
 */
public class PasswordUpdateDTO {

    @NotBlank
    private String oldPassword;

    @NotBlank
    @StrongPassword
    private String newPassword;

    public String getOldPassword() { return oldPassword; }
    public void setOldPassword(String oldPassword) { this.oldPassword = oldPassword; }

    public String getNewPassword() { return newPassword; }
    public void setNewPassword(String newPassword) { this.newPassword = newPassword; }
}
