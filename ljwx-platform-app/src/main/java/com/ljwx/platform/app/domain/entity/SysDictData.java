package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 字典数据实体，对应 sys_dict_data 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysDictData extends BaseEntity {

    /** 主键ID（Snowflake） */
    private Long id;

    /** 字典类型，关联 sys_dict_type.dict_type */
    private String dictType;

    /** 字典标签（显示名称） */
    private String dictLabel;

    /** 字典键值 */
    private String dictValue;

    /** 显示顺序 */
    private Integer sortOrder;

    /** 状态：1-正常，0-停用 */
    private Integer status;

    /** 样式属性（前端使用） */
    private String cssClass;

    /** 表格回显样式（前端使用） */
    private String listClass;

    /** 是否默认值 */
    private Boolean isDefault;

    /** 备注 */
    private String remark;
}
