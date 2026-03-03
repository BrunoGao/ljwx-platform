package com.ljwx.platform.app.service;

import com.ljwx.platform.app.domain.RptReportDef;
import com.ljwx.platform.app.dto.report.ReportExecuteDTO;
import com.ljwx.platform.app.mapper.RptReportDefMapper;
import com.ljwx.platform.app.vo.report.ReportResultVO;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Report Execute Service
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RptReportExecuteService {

    private final RptReportDefMapper reportDefMapper;
    private final JdbcTemplate jdbcTemplate;

    /**
     * Execute report query
     * Security requirements:
     * 1. query_template only allows #{paramName} placeholders, forbid ${} direct concatenation
     * 2. Forbid INSERT/UPDATE/DELETE/DROP/TRUNCATE keywords (regex validation)
     * 3. Page size cannot exceed 1000 rows
     * 4. Execution timeout 30s
     * 5. Tenant isolation: automatically append "AND tenant_id = #{tenantId}" before execution
     *    - If SQL contains WHERE, append "AND tenant_id = #{tenantId}"
     *    - If SQL has no WHERE, append "WHERE tenant_id = #{tenantId}"
     *    - Forbid users from manually writing tenant_id condition in query_template
     *
     * @param reportId report ID
     * @param dto execute DTO
     * @return report result
     */
    public ReportResultVO execute(Long reportId, ReportExecuteDTO dto) {
        // Get report definition
        RptReportDef reportDef = reportDefMapper.selectById(reportId);
        if (reportDef == null || Boolean.TRUE.equals(reportDef.getDeleted())) {
            throw new BusinessException(404, "Report definition not found");
        }

        // Check if report is enabled
        if (reportDef.getStatus() != 1) {
            throw new BusinessException(400, "Report is disabled");
        }

        // Validate parameters
        Map<String, Object> params = dto.getParams() != null ? dto.getParams() : new HashMap<>();
        validateParameters(reportDef, params);

        // Apply page size limit
        List<String> warnings = new ArrayList<>();
        Integer pageSize = dto.getPageSize();
        if (pageSize == null) {
            pageSize = 100; // Default page size
        } else if (pageSize > 1000) {
            pageSize = 1000;
            warnings.add("pageSize has been truncated to 1000");
        }

        Integer pageNum = dto.getPageNum() != null ? dto.getPageNum() : 1;
        int offset = (pageNum - 1) * pageSize;

        // Add tenant_id to parameters
        Long tenantId = CurrentTenantHolder.get();
        params.put("tenantId", tenantId);

        // Build SQL with tenant isolation
        String sql = buildSecureSQL(reportDef.getQueryTemplate(), pageSize, offset);

        // Execute query
        long startTime = System.currentTimeMillis();
        List<Map<String, Object>> rows;
        try {
            rows = jdbcTemplate.queryForList(sql, params.values().toArray());
        } catch (Exception e) {
            log.error("Failed to execute report query: {}", e.getMessage(), e);
            throw new BusinessException(500, "Failed to execute report query: " + e.getMessage());
        }
        long duration = System.currentTimeMillis() - startTime;

        // Warn if query took too long
        if (duration > 10000) {
            warnings.add("Query took " + duration + "ms, consider optimizing the SQL");
        }

        // Count total rows (without pagination)
        String countSql = buildCountSQL(reportDef.getQueryTemplate());
        Long total;
        try {
            total = jdbcTemplate.queryForObject(countSql, Long.class, params.values().toArray());
        } catch (Exception e) {
            log.error("Failed to count report rows: {}", e.getMessage(), e);
            total = (long) rows.size();
        }

        // Build column metadata
        List<ReportResultVO.ColumnMeta> columns = buildColumnMeta(reportDef.getColumnDef());

        // Build result
        ReportResultVO result = new ReportResultVO();
        result.setColumns(columns);
        result.setRows(rows);
        result.setTotal(total);
        result.setPageNum(pageNum);
        result.setPageSize(pageSize);
        result.setWarnings(warnings.isEmpty() ? null : warnings);

        return result;
    }

    /**
     * Validate parameters against filter definition
     */
    private void validateParameters(RptReportDef reportDef, Map<String, Object> params) {
        List<Map<String, Object>> filterDef = reportDef.getFilterDef();
        if (filterDef == null || filterDef.isEmpty()) {
            return;
        }

        // Extract defined parameter names
        Set<String> definedParams = filterDef.stream()
                .map(f -> (String) f.get("name"))
                .collect(Collectors.toSet());

        // Check if all provided params are defined
        for (String paramName : params.keySet()) {
            if (!definedParams.contains(paramName)) {
                throw new BusinessException(400, "Parameter '" + paramName + "' is not defined in filter definition");
            }
        }

        // Check required parameters
        for (Map<String, Object> filter : filterDef) {
            String name = (String) filter.get("name");
            Boolean required = (Boolean) filter.get("required");
            if (Boolean.TRUE.equals(required) && !params.containsKey(name)) {
                throw new BusinessException(400, "Required parameter '" + name + "' is missing");
            }
        }
    }

    /**
     * Build secure SQL with tenant isolation and pagination
     */
    private String buildSecureSQL(String queryTemplate, int pageSize, int offset) {
        // Replace #{paramName} with ? placeholders
        String sql = replaceNamedParameters(queryTemplate);

        // Append tenant isolation condition
        sql = appendTenantCondition(sql);

        // Append pagination
        sql = sql + " LIMIT " + pageSize + " OFFSET " + offset;

        return sql;
    }

    /**
     * Build count SQL for total rows
     */
    private String buildCountSQL(String queryTemplate) {
        String sql = replaceNamedParameters(queryTemplate);
        sql = appendTenantCondition(sql);

        // Wrap with COUNT(*)
        return "SELECT COUNT(*) FROM (" + sql + ") AS count_query";
    }

    /**
     * Replace #{paramName} with ? placeholders
     */
    private String replaceNamedParameters(String queryTemplate) {
        Pattern pattern = Pattern.compile("#\\{([a-zA-Z0-9_]+)\\}");
        Matcher matcher = pattern.matcher(queryTemplate);
        return matcher.replaceAll("?");
    }

    /**
     * Append tenant_id condition to SQL
     */
    private String appendTenantCondition(String sql) {
        String upperSql = sql.toUpperCase();
        if (upperSql.contains("WHERE")) {
            // SQL already has WHERE clause, append AND condition
            return sql + " AND tenant_id = ?";
        } else {
            // SQL has no WHERE clause, add WHERE condition
            return sql + " WHERE tenant_id = ?";
        }
    }

    /**
     * Build column metadata from column definition
     */
    private List<ReportResultVO.ColumnMeta> buildColumnMeta(List<Map<String, Object>> columnDef) {
        return columnDef.stream().map(col -> {
            ReportResultVO.ColumnMeta meta = new ReportResultVO.ColumnMeta();
            meta.setName((String) col.get("name"));
            meta.setTitle((String) col.get("title"));
            meta.setType((String) col.get("type"));
            return meta;
        }).collect(Collectors.toList());
    }
}
