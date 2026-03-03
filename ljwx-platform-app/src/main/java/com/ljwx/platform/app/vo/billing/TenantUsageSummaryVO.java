package com.ljwx.platform.app.vo.billing;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Tenant usage summary VO (for superadmin only)
 */
@Data
public class TenantUsageSummaryVO {

    /**
     * Tenant ID (only returned in superadmin interfaces)
     */
    private Long tenantId;

    /**
     * Tenant name
     */
    private String tenantName;

    /**
     * Expire time
     */
    private LocalDateTime expireTime;

    /**
     * Latest user count
     */
    private Long userCount;

    /**
     * Latest storage usage (MB)
     */
    private BigDecimal storageMb;

    /**
     * Total API calls in last 30 days
     */
    private Long apiCallsTotal;

    /**
     * Login count in last 30 days
     */
    private Long loginCountLast30d;

    /**
     * Is expiring soon (within 30 days)
     */
    private Boolean isExpiringSoon;
}
