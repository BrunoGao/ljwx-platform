package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 前端错误上报 DTO。
 */
@Data
public class FrontendErrorDTO {

    @NotBlank(message = "错误信息不能为空")
    private String errorMessage;

    @NotBlank(message = "堆栈信息不能为空")
    private String stackTrace;

    @NotBlank(message = "页面 URL 不能为空")
    private String pageUrl;

    @NotBlank(message = "浏览器信息不能为空")
    private String userAgent;
}
