package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.Map;

/**
 * Form data entity
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "sys_form_data", autoResultMap = true)
public class FormData extends BaseEntity {

    /**
     * Form definition ID
     */
    private Long formDefId;

    /**
     * Form field values (JSON object)
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private Map<String, Object> fieldValues;

    /**
     * Creator user ID
     */
    private Long creatorId;

    /**
     * Creator department ID
     */
    private Long creatorDeptId;
}
