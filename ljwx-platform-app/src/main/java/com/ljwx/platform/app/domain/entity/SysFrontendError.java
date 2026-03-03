package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 前端错误监控实体，对应 sys_frontend_error 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysFrontendError extends BaseEntity {

    private Long id;
    private String errorMessage;
    private String stackTrace;
    private String pageUrl;
    private String userAgent;
}
