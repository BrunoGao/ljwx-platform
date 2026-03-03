package com.ljwx.platform.app.vo.form;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * Form definition VO
 */
@Data
public class FormDefVO {

    /**
     * Primary key
     */
    private Long id;

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
    private Object schema;

    /**
     * Status: 1=enabled, 0=disabled
     */
    private Integer status;

    /**
     * Remark
     */
    private String remark;

    /**
     * Created time
     */
    private LocalDateTime createdTime;

    /**
     * Updated time
     */
    private LocalDateTime updatedTime;
}
