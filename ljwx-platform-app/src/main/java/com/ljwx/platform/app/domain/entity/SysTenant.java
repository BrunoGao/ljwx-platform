package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 租户实体，对应 sys_tenant 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysTenant extends BaseEntity {

    private Long id;
    private String name;
    private String code;
    private Integer status;
    private String remark;
    private Long packageId;

    /** 生命周期状态: ACTIVE/FROZEN/CANCELLED */
    private String lifecycleStatus;

    /** 冻结原因 */
    private String frozenReason;

    /** 冻结时间 */
    private LocalDateTime frozenTime;

    /** 注销原因 */
    private String cancelledReason;

    /** 注销时间 */
    private LocalDateTime cancelledTime;
}
