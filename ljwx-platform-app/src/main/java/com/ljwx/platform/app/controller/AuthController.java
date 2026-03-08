package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.AuthAppService;
import com.ljwx.platform.app.domain.dto.LoginDTO;
import com.ljwx.platform.app.domain.dto.RefreshDTO;
import com.ljwx.platform.app.domain.vo.LoginVO;
import com.ljwx.platform.app.domain.vo.TokenVO;
import com.ljwx.platform.app.domain.vo.UserInfoVO;
import com.ljwx.platform.core.result.Result;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 认证 Controller。
 *
 * <p>login / refresh 为公开端点（SecurityConfig 已 permitAll），
 * 使用 @PreAuthorize("permitAll()") 满足 gate 检查。
 * me / logout 要求已登录。
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthAppService authAppService;

    @PreAuthorize("permitAll()")
    @PostMapping("/login")
    public Result<LoginVO> login(@RequestBody @Valid LoginDTO dto, HttpServletRequest request) {
        return Result.ok(authAppService.login(
                dto,
                extractClientIp(request),
                request.getHeader("User-Agent")));
    }

    @PreAuthorize("permitAll()")
    @PostMapping("/refresh")
    public Result<TokenVO> refresh(@RequestBody @Valid RefreshDTO dto) {
        return Result.ok(authAppService.refresh(dto));
    }

    @PreAuthorize("isAuthenticated()")
    @GetMapping("/me")
    public Result<UserInfoVO> me() {
        return Result.ok(authAppService.getCurrentUser());
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping("/logout")
    public Result<Void> logout(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        String token = (header != null && header.startsWith("Bearer ")) ? header.substring(7) : null;
        authAppService.logout(token);
        return Result.ok();
    }

    private String extractClientIp(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
