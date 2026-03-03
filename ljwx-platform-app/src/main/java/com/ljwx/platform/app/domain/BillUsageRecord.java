package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableName;
import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Tenant usage record entity
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("bill_usage_record")
public class BillUsageRecord extends BaseEntity {

    /**
     * Metric type: USER_COUNT/STORAGE_MB/API_CALLS/LOGIN_COUNT/FILE_COUNT
     */
    private String metricType;

    /**
     * Usage value
     */
    private BigDecimal usageValue;

    /**
     * Record date (daily)
     */
    private LocalDate recordDate;
}
