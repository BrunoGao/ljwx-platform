package com.ljwx.platform.app.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ljwx.platform.app.domain.BillUsageRecord;
import com.ljwx.platform.app.vo.billing.DailyStatVO;
import com.ljwx.platform.app.vo.billing.TenantUsageSummaryVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Bill usage record mapper
 */
@Mapper
public interface BillUsageRecordMapper extends BaseMapper<BillUsageRecord> {

    /**
     * Batch insert or update usage records (idempotent)
     *
     * @param records usage records
     */
    void batchUpsertUsageRecords(@Param("records") List<BillUsageRecord> records);

    /**
     * Count active tenants (with login records in recent days)
     *
     * @param recentDays recent days
     * @return active tenant count
     */
    Long countActiveTenants(@Param("recentDays") int recentDays);

    /**
     * Get daily active users (DAU) trend
     *
     * @param recentDays recent days
     * @return daily stats
     */
    List<DailyStatVO> getDailyActiveUsers(@Param("recentDays") int recentDays);

    /**
     * Sum total storage (MB) across all tenants
     *
     * @return total storage MB
     */
    BigDecimal sumStorageMb();

    /**
     * Sum API calls today
     *
     * @return total API calls today
     */
    Long sumApiCallsToday();

    /**
     * Get tenant usage summary list
     *
     * @return tenant usage summary list
     */
    List<TenantUsageSummaryVO> getTenantUsageSummaryList();
}
