package com.ljwx.platform.app.vo.billing;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Usage record VO
 */
@Data
public class UsageRecordVO {

    /**
     * Primary key
     */
    private Long id;

    /**
     * Metric type: USER_COUNT/STORAGE_MB/API_CALLS/LOGIN_COUNT/FILE_COUNT
     */
    private String metricType;

    /**
     * Usage value
     */
    private BigDecimal usageValue;

    /**
     * Record date
     */
    private LocalDate recordDate;
}
