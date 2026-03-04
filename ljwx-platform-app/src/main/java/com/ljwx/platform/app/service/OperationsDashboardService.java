package com.ljwx.platform.app.service;

import com.ljwx.platform.app.mapper.BillUsageRecordMapper;
import com.ljwx.platform.app.vo.billing.DailyStatVO;
import com.ljwx.platform.app.vo.billing.TenantUsageSummaryVO;
import com.ljwx.platform.app.vo.ops.OperationsDashboardVO;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Operations dashboard service
 */
@Service
@RequiredArgsConstructor
public class OperationsDashboardService {

    private final BillUsageRecordMapper billUsageRecordMapper;

    /**
     * Get operations dashboard data (superadmin only)
     *
     * @return operations dashboard VO
     */
    public OperationsDashboardVO getDashboard() {
        // Verify superadmin identity (tenant_id == 0)
        Long currentTenantId = CurrentTenantHolder.get();
        if (currentTenantId == null || currentTenantId.longValue() != 0L) {
            throw new AccessDeniedException("Only superadmin can access operations dashboard");
        }

        // Get all tenant usage summaries first, then derive dashboard counters.
        List<TenantUsageSummaryVO> allTenants = billUsageRecordMapper.getTenantUsageSummaryList();
        Long totalTenants = (long) allTenants.size();

        // Get active tenant count (with login in recent 7 days)
        Long activeTenants = billUsageRecordMapper.countActiveTenants(7);

        // Get expiring soon tenants (within 30 days)
        List<TenantUsageSummaryVO> expiringSoon = allTenants.stream()
                .filter(t -> t.getIsExpiringSoon() != null && t.getIsExpiringSoon())
                .collect(Collectors.toList());

        // Get daily active users (DAU) trend for last 30 days
        List<DailyStatVO> dailyActiveUsers = billUsageRecordMapper.getDailyActiveUsers(30);

        // Get total storage (MB)
        BigDecimal totalStorageMb = billUsageRecordMapper.sumStorageMb();
        if (totalStorageMb == null) {
            totalStorageMb = BigDecimal.ZERO;
        }

        // Get total API calls today
        Long totalApiCallsToday = billUsageRecordMapper.sumApiCallsToday();
        if (totalApiCallsToday == null) {
            totalApiCallsToday = 0L;
        }

        return OperationsDashboardVO.builder()
                .totalTenants(totalTenants)
                .activeTenants(activeTenants)
                .expiringSoon(expiringSoon)
                .dailyActiveUsers(dailyActiveUsers)
                .totalStorageMb(totalStorageMb)
                .totalApiCallsToday(totalApiCallsToday)
                .build();
    }
}
