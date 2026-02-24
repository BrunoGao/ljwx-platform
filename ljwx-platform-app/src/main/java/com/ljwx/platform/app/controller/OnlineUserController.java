package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.OnlineUserAppService;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 在线用户 Controller。
 *
 * <p>路由：
 * <ul>
 *   <li>GET    /api/v1/online-users           — 查询在线用户列表</li>
 *   <li>DELETE /api/v1/online-users/{tokenId} — 强制下线</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/online-users")
@RequiredArgsConstructor
public class OnlineUserController {

    private final OnlineUserAppService onlineUserAppService;

    @PreAuthorize("hasAuthority('system:online:list')")
    @GetMapping
    public Result<List<Map<String, String>>> list() {
        return Result.ok(onlineUserAppService.listOnlineUsers());
    }

    @PreAuthorize("hasAuthority('system:online:kickout')")
    @DeleteMapping("/{tokenId}")
    public Result<Void> kickout(@PathVariable String tokenId) {
        onlineUserAppService.kickout(tokenId);
        return Result.ok();
    }
}
