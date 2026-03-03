package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Form definition entity
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "sys_form_def", autoResultMap = true)
public class FormDef extends BaseEntity {

    /**
     * Form name
     */
    private String formName;

    /**
     * Form unique key
     */
    private String formKey;

    /**
     * Form JSON Schema (fields, validation, layout)
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private Object schema;

    /**
     * Status: 1=enabled, 0=disabled
     */
    private Integer status;

    /**
     * Remark
     */
    private String remark;
}
