package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 租户域名实体
 *
 * <p>对应表：sys_tenant_domain
 * <p>功能：租户域名识别，支持自定义域名绑定
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class TenantDomain extends BaseEntity {

    /**
     * 主键（雪花 ID）
     */
    private Long id;

    /**
     * 域名（如 tenant1.ljwx.com）
     */
    private String domain;

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
     * 验证 token
     */
    private String verifyToken;

    /**
     * 备注
     */
    private String remark;
}
