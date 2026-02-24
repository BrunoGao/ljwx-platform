package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 部门实体，对应 sys_dept 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysDept extends BaseEntity {

    private Long id;

    /** 父部门ID，0 = 根节点 */
    private Long parentId;

    /** 部门名称 */
    private String name;

    /** 显示排序 */
    private Integer sort;

    /** 负责人 */
    private String leader;

    /** 联系电话 */
    private String phone;

    /** 邮箱 */
    private String email;

    /** 状态：1=正常，0=停用 */
    private Integer status;
}
