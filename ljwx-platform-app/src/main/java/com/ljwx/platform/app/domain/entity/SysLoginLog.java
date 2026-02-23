package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 登录日志实体，对应 sys_login_log 表。
 *
 * <p>由认证模块在用户登录/登出时写入，记录登录结果和客户端信息。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysLoginLog extends BaseEntity {

    /** 主键ID（Snowflake） */
    private Long id;

    /** 登录账号 */
    private String username;

    /** 登录 IP 地址 */
    private String ip;

    /** 登录地点（从 IP 解析，如"北京市"） */
    private String location;

    /** 浏览器类型 */
    private String browser;

    /** 操作系统 */
    private String os;

    /** 登录状态：0-成功, 1-失败 */
    private Integer status;

    /** 提示消息（失败时记录原因） */
    private String msg;
}
