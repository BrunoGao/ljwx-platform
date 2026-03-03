package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 角色实体，对应 sys_role 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysRole extends BaseEntity {

    private Long id;
    private String name;
    private String code;
    /** 状态：1-启用，0-禁用 */
    private Integer status;
    private String remark;
}
