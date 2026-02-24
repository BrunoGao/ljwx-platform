package com.ljwx.platform.app.domain.vo;

import lombok.Data;

/**
 * Token 响应（用于 /api/auth/refresh）。
 */
@Data
public class TokenVO {

    private String accessToken;
    private String refreshToken;
    /** Access Token 过期秒数 */
    private long expiresIn;
}
