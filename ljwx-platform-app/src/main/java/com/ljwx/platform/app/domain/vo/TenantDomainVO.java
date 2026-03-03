package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 租户域名 VO
 */
@Data
public class TenantDomainVO {

    /**
     * 主键
     */
    private Long id;

    /**
     * 域名
     */
    private String domain;

    /**
     * 租户 ID
     */
    private Long tenantId;

    /**
     * 状态：ENABLED / DISABLED
     */
    private String status;

    /**
     * 是否主域名
     */
    private Boolean isPrimary;

    /**
     * 是否已验证
     */
    private Boolean verified;

    /**
     * 验证时间
     */
    private LocalDateTime verifiedTime;

    /**
     * 备注
     */
    private String remark;

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    private LocalDateTime updatedTime;
}
