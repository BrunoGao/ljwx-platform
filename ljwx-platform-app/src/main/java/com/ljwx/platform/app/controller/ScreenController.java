package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.service.ScreenService;
import com.ljwx.platform.app.vo.screen.ScreenOverviewVO;
import com.ljwx.platform.app.vo.screen.ScreenRealtimeVO;
import com.ljwx.platform.app.vo.screen.ScreenTrendVO;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Screen controller.
 */
@RestController
@RequestMapping("/api/v1/screen")
@RequiredArgsConstructor
public class ScreenController {

    private final ScreenService screenService;

    @PreAuthorize("hasAnyAuthority('system:screen:read', 'screen:read')")
    @GetMapping("/overview")
    public Result<ScreenOverviewVO> overview() {
        return Result.ok(screenService.getOverview());
    }

    @PreAuthorize("hasAnyAuthority('system:screen:read', 'screen:read')")
    @GetMapping("/realtime")
    public Result<ScreenRealtimeVO> realtime() {
        return Result.ok(screenService.getRealtime());
    }

    @PreAuthorize("hasAnyAuthority('system:screen:read', 'screen:read')")
    @GetMapping("/trend")
    public Result<ScreenTrendVO> trend() {
        return Result.ok(screenService.getTrend());
    }
}
