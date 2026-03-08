package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 租户视图对象。
 */
@Data
public class TenantVO {

    private Long id;
    private String name;
    private String code;
    private Integer status;
    private String lifecycleStatus;
    private String frozenReason;
    private LocalDateTime frozenTime;
    private String cancelledReason;
    private LocalDateTime cancelledTime;
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
}
