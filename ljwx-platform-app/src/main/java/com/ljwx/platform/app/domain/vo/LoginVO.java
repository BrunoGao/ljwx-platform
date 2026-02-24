package com.ljwx.platform.app.domain.vo;

import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 登录响应 = Token 信息 + 用户信息。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class LoginVO extends TokenVO {

    private UserInfoVO userInfo;
}
