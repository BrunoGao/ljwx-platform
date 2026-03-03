package com.ljwx.platform.app.vo.form;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Custom field definition VO
 */
@Data
public class CustomFieldDefVO {

    /**
     * Primary key
     */
    private Long id;

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
     * Options for SELECT/CHECKBOX
     */
    private List<Object> options;

    /**
     * Created time
     */
    private LocalDateTime createdTime;
}
