package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.domain.dto.LoginLogQueryDTO;
import com.ljwx.platform.app.domain.entity.SysLoginLog;
import com.ljwx.platform.app.infra.mapper.SysLoginLogMapper;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 登录日志 Controller。
 * 权限按 spec/03-api.md §Logs 路由定义。
 *
 * <p>路由：
 * <ul>
 *   <li>GET /api/logs/login — log:read — 登录日志列表</li>
 * </ul>
 *
 * <p>登录日志由认证模块在用户登录时写入，本 Controller 仅提供只读查询。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 实现行级隔离。
 */
@RestController
@RequestMapping("/api/logs/login")
@RequiredArgsConstructor
public class LoginLogController {

    private final SysLoginLogMapper loginLogMapper;

    /**
     * 查询登录日志列表（分页）。
     */
    @PreAuthorize("hasAuthority('log:read')")
    @GetMapping
    public Result<PageResult<SysLoginLog>> listLoginLogs(LoginLogQueryDTO query) {
        List<SysLoginLog> records = loginLogMapper.selectList(query);
        long total = loginLogMapper.countList(query);
        return Result.ok(new PageResult<>(records, total));
    }
}
