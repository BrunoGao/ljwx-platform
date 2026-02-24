package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 租户套餐视图对象
 */
@Data
public class TenantPackageVO {

    private Long id;
    private String name;
    private String menuIds;
    private Integer maxUsers;
    private Integer maxStorageMb;
    private Integer status;
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
}
