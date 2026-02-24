package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 权限实体，对应 sys_permission 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysPermission extends BaseEntity {

    private Long id;
    /** 权限标识，格式：resource:action，如 user:read */
    private String code;
    private String name;
    private String remark;
}
