package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.ProfileAppService;
import com.ljwx.platform.app.domain.dto.PasswordUpdateDTO;
import com.ljwx.platform.app.domain.dto.ProfileUpdateDTO;
import com.ljwx.platform.app.domain.vo.UserInfoVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 个人中心 Controller。
 *
 * <p>路由：
 * <ul>
 *   <li>GET  /api/v1/profile          — 获取当前用户信息</li>
 *   <li>PUT  /api/v1/profile          — 修改个人信息</li>
 *   <li>PUT  /api/v1/profile/password — 修改密码</li>
 * </ul>
 *
 * <p>所有方法要求已认证（JWT），无需额外权限码。
 */
@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileAppService profileAppService;

    @PreAuthorize("isAuthenticated()")
    @GetMapping
    public Result<UserInfoVO> getProfile() {
        return Result.ok(profileAppService.getProfile());
    }

    @PreAuthorize("isAuthenticated()")
    @PutMapping
    public Result<Void> updateProfile(@RequestBody @Valid ProfileUpdateDTO dto) {
        profileAppService.updateProfile(dto);
        return Result.ok();
    }

    @PreAuthorize("isAuthenticated()")
    @PutMapping("/password")
    public Result<Void> updatePassword(@RequestBody @Valid PasswordUpdateDTO dto) {
        profileAppService.updatePassword(dto);
        return Result.ok();
    }
}
