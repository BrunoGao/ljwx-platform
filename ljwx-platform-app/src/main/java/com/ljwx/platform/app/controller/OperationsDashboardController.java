package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.service.OperationsDashboardService;
import com.ljwx.platform.app.vo.ops.OperationsDashboardVO;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Operations dashboard controller.
 */
@RestController
@RequestMapping("/api/v1/ops")
@RequiredArgsConstructor
public class OperationsDashboardController {

    private final OperationsDashboardService operationsDashboardService;

    @PreAuthorize("hasAuthority('system:ops:dashboard')")
    @GetMapping("/dashboard")
    public Result<OperationsDashboardVO> getDashboard() {
        return Result.ok(operationsDashboardService.getDashboard());
    }
}
