package com.ljwx.platform.app.dto.form;

import lombok.Data;

/**
 * Form definition query DTO
 */
@Data
public class FormDefQueryDTO {

    /**
     * Form name (fuzzy search)
     */
    private String formName;

    /**
     * Form key (fuzzy search)
     */
    private String formKey;

    /**
     * Status: 1=enabled, 0=disabled
     */
    private Integer status;

    /**
     * Page number
     */
    private Integer pageNum = 1;

    /**
     * Page size
     */
    private Integer pageSize = 10;
}
