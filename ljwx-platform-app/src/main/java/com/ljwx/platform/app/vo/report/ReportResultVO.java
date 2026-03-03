package com.ljwx.platform.app.vo.report;

import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * Report Result VO
 */
@Data
public class ReportResultVO {

    /**
     * Column metadata (name, title, type)
     */
    private List<ColumnMeta> columns;

    /**
     * Data rows
     */
    private List<Map<String, Object>> rows;

    /**
     * Total row count
     */
    private Long total;

    /**
     * Current page number
     */
    private Integer pageNum;

    /**
     * Page size
     */
    private Integer pageSize;

    /**
     * Warning messages (e.g., pageSize truncated, query took too long)
     */
    private List<String> warnings;

    /**
     * Column metadata
     */
    @Data
    public static class ColumnMeta {
        /**
         * Column name
         */
        private String name;

        /**
         * Column title
         */
        private String title;

        /**
         * Column type
         */
        private String type;
    }
}
