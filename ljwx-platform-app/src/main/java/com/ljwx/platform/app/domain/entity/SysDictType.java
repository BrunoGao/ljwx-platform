package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 字典类型实体，对应 sys_dict_type 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysDictType extends BaseEntity {

    /** 主键ID（Snowflake） */
    private Long id;

    /** 字典名称（显示用） */
    private String dictName;

    /** 字典类型（唯一标识，如 sys_user_sex） */
    private String dictType;

    /** 状态：1-正常，0-停用 */
    private Integer status;

    /** 备注 */
    private String remark;
}
