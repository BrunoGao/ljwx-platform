package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.billing.BillingQueryDTO;
import com.ljwx.platform.app.service.BillUsageAppService;
import com.ljwx.platform.app.vo.billing.TenantUsageSummaryVO;
import com.ljwx.platform.app.vo.billing.UsageRecordVO;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Billing controller
 */
@RestController
@RequestMapping("/api/v1/billing")
@RequiredArgsConstructor
public class BillingController {

    private final BillUsageAppService billUsageAppService;

    /**
     * List usage records
     *
     * @param query query DTO
     * @return usage record list
     */
    @PreAuthorize("hasAuthority('system:billing:list')")
    @GetMapping("/usage")
    public Result<List<UsageRecordVO>> listUsageRecords(@Valid BillingQueryDTO query) {
        List<UsageRecordVO> records = billUsageAppService.listUsageRecords(query);
        return Result.ok(records);
    }

    /**
     * Get tenant usage summary (superadmin only)
     *
     * @return tenant usage summary list
     */
    @PreAuthorize("hasAuthority('system:billing:list')")
    @GetMapping("/summary")
    public Result<List<TenantUsageSummaryVO>> getTenantUsageSummary() {
        // Verify superadmin identity
        Long currentTenantId = CurrentTenantHolder.get();
        if (currentTenantId == null || currentTenantId.longValue() != 0L) {
            throw new AccessDeniedException("Only superadmin can access tenant usage summary");
        }

        List<TenantUsageSummaryVO> summary = billUsageAppService.getTenantUsageSummary();
        return Result.ok(summary);
    }
}
