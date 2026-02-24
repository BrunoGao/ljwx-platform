package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.OffsetDateTime;

/**
 * 登录日志视图对象。
 */
@Data
public class LoginLogVO {

    private Long id;
    private String username;
    private String ipAddress;
    private String userAgent;
    /** 1=成功，0=失败 */
    private Integer status;
    private String message;
    private OffsetDateTime loginTime;
}
