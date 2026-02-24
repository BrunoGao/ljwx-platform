package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.LoginLogAppService;
import com.ljwx.platform.app.domain.dto.LoginLogQueryDTO;
import com.ljwx.platform.app.domain.vo.LoginLogVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 登录日志 Controller。
 *
 * <p>路由：GET /api/v1/login-logs — 分页查询登录日志
 */
@RestController
@RequestMapping("/api/v1/login-logs")
@RequiredArgsConstructor
public class LoginLogController {

    private final LoginLogAppService loginLogAppService;

    @PreAuthorize("hasAuthority('system:log:login:list')")
    @GetMapping
    public Result<PageResult<LoginLogVO>> list(LoginLogQueryDTO query) {
        return Result.ok(loginLogAppService.listLoginLogs(query));
    }
}
