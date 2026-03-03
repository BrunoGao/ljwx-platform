package com.ljwx.platform.app.vo.help;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * Help doc VO
 */
@Data
public class HelpDocVO {

    /**
     * Primary key
     */
    private Long id;

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
     * Associated route
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

    /**
     * Created time
     */
    private LocalDateTime createdTime;

    /**
     * Updated time
     */
    private LocalDateTime updatedTime;
}
