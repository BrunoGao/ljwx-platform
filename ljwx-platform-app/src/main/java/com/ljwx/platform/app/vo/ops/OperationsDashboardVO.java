package com.ljwx.platform.app.vo.ops;

import com.ljwx.platform.app.vo.billing.DailyStatVO;
import com.ljwx.platform.app.vo.billing.TenantUsageSummaryVO;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * Operations dashboard VO
 */
@Data
@Builder
public class OperationsDashboardVO {

    /**
     * Total tenant count
     */
    private Long totalTenants;

    /**
     * Active tenant count (with login in recent 7 days)
     */
    private Long activeTenants;

    /**
     * Expiring soon tenant list (within 30 days)
     */
    private List<TenantUsageSummaryVO> expiringSoon;

    /**
     * Daily active users (DAU) trend for last 30 days
     */
    private List<DailyStatVO> dailyActiveUsers;

    /**
     * Total storage usage (MB) across all tenants
     */
    private BigDecimal totalStorageMb;

    /**
     * Total API calls today
     */
    private Long totalApiCallsToday;
}
