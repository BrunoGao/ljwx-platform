package com.ljwx.platform.core.entity;

import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 所有业务实体的基类，携带 7 个审计字段。
 *
 * <p>字段映射（对应 SQL DDL spec/01-constraints.md §审计字段）：
 * <pre>
 *   tenant_id    BIGINT       NOT NULL
 *   created_by   BIGINT       NOT NULL DEFAULT 0
 *   created_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
 *   updated_by   BIGINT       NOT NULL DEFAULT 0
 *   updated_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
 *   deleted      BOOLEAN      NOT NULL DEFAULT FALSE
 *   version      INT          NOT NULL DEFAULT 1
 * </pre>
 *
 * <p>AuditFieldInterceptor（data 模块）在 INSERT/UPDATE 时自动填写
 * created_by / updated_by（从 CurrentUserHolder 读取）。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ?。
 */
@Data
public abstract class BaseEntity implements Serializable {

    /** 租户 ID，由 TenantLineInterceptor 自动注入，禁止在 DTO 中暴露 */
    private Long tenantId;

    /** 创建人 ID，由 AuditFieldInterceptor 在 INSERT 时写入 */
    private Long createdBy;

    /** 创建时间 */
    private LocalDateTime createdTime;

    /** 最后更新人 ID，由 AuditFieldInterceptor 在 UPDATE 时写入 */
    private Long updatedBy;

    /** 最后更新时间 */
    private LocalDateTime updatedTime;

    /** 逻辑删除标记（false = 正常，true = 已删除） */
    private Boolean deleted;

    /** 乐观锁版本号 */
    private Integer version;
}
