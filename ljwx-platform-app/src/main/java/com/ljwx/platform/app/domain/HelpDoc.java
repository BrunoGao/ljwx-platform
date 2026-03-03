package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableName;
import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Help documentation entity
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_help_doc")
public class HelpDoc extends BaseEntity {

    /**
     * Document unique key
     */
    private String docKey;

    /**
     * Document title
     */
    private String title;

    /**
     * Markdown content
     */
    private String content;

    /**
     * Category
     */
    private String category;

    /**
     * Associated frontend route (supports wildcard)
     */
    private String routeMatch;

    /**
     * Sort order
     */
    private Integer sortOrder;

    /**
     * Status: 1 enabled, 0 disabled
     */
    private Integer status;
}
