package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.OffsetDateTime;

/**
 * 登录日志实体，对应 sys_login_log 表。
 *
 * <p>由认证模块在用户登录时异步写入，记录登录结果和客户端信息。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysLoginLog extends BaseEntity {

    /** 主键ID（Snowflake） */
    private Long id;

    /** 登录用户名 */
    private String username;

    /** 登录 IP 地址 */
    private String ipAddress;

    /** 客户端 User-Agent */
    private String userAgent;

    /** 登录状态：1=成功，0=失败 */
    private Integer status;

    /** 提示消息 */
    private String message;

    /** 登录时间 */
    private OffsetDateTime loginTime;
}
