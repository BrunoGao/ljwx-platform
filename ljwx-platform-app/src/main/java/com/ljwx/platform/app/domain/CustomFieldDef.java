package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

/**
 * Custom field definition entity
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "sys_custom_field_def", autoResultMap = true)
public class CustomFieldDef extends BaseEntity {

    /**
     * Entity type (USER/DEPT/...)
     */
    private String entityType;

    /**
     * Field unique key
     */
    private String fieldKey;

    /**
     * Field display label
     */
    private String fieldLabel;

    /**
     * Field type (TEXT/NUMBER/DATE/SELECT/CHECKBOX)
     */
    private String fieldType;

    /**
     * Is required
     */
    private Boolean required;

    /**
     * Sort order
     */
    private Integer sortOrder;

    /**
     * Options for SELECT/CHECKBOX (JSON array)
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<Object> options;
}
