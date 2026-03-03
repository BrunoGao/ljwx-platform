package com.ljwx.platform.app.service;

import com.ljwx.platform.app.domain.RptReportDef;
import com.ljwx.platform.app.dto.report.ReportDefCreateDTO;
import com.ljwx.platform.app.dto.report.ReportDefQueryDTO;
import com.ljwx.platform.app.dto.report.ReportDefUpdateDTO;
import com.ljwx.platform.app.mapper.RptReportDefMapper;
import com.ljwx.platform.app.vo.report.ReportDefVO;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.exception.BusinessException;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Report Definition Application Service
 */
@Service
@RequiredArgsConstructor
public class RptReportDefAppService {

    private final RptReportDefMapper reportDefMapper;

    /**
     * Query report definition list with pagination
     *
     * @param query query conditions
     * @return paginated report definition list
     */
    public PageResult<ReportDefVO> list(ReportDefQueryDTO query) {
        List<ReportDefVO> list = reportDefMapper.selectReportDefList(query);
        long total = reportDefMapper.countReportDefs(query);
        return new PageResult<>(list, total);
    }

    /**
     * Get report definition by ID
     *
     * @param id report ID
     * @return report definition VO
     */
    public ReportDefVO getById(Long id) {
        ReportDefVO vo = reportDefMapper.selectReportDefById(id);
        if (vo == null) {
            throw new BusinessException(404, "Report definition not found");
        }
        return vo;
    }

    /**
     * Create report definition
     *
     * @param dto create DTO
     * @return report ID
     */
    @Transactional
    public Long create(ReportDefCreateDTO dto) {
        // Validate query template
        validateQueryTemplate(dto.getQueryTemplate());

        // Check if report key already exists in tenant
        Long tenantId = CurrentTenantHolder.get();
        int count = reportDefMapper.countByReportKey(tenantId, dto.getReportKey(), null);
        if (count > 0) {
            throw new BusinessException(409, "Report key already exists in this tenant");
        }

        // Create entity
        RptReportDef entity = new RptReportDef();
        entity.setReportName(dto.getReportName());
        entity.setReportKey(dto.getReportKey());
        entity.setDataSourceType(dto.getDataSourceType());
        entity.setQueryTemplate(dto.getQueryTemplate());
        entity.setColumnDef(dto.getColumnDef());
        entity.setFilterDef(dto.getFilterDef());
        entity.setStatus(1); // Default enabled
        entity.setRemark(dto.getRemark());

        reportDefMapper.insert(entity);
        return entity.getId();
    }

    /**
     * Update report definition
     *
     * @param id report ID
     * @param dto update DTO
     */
    @Transactional
    public void update(Long id, ReportDefUpdateDTO dto) {
        // Validate query template
        validateQueryTemplate(dto.getQueryTemplate());

        // Check if report exists
        RptReportDef entity = reportDefMapper.selectById(id);
        if (entity == null || Boolean.TRUE.equals(entity.getDeleted())) {
            throw new BusinessException(404, "Report definition not found");
        }

        // Update entity
        entity.setReportName(dto.getReportName());
        entity.setDataSourceType(dto.getDataSourceType());
        entity.setQueryTemplate(dto.getQueryTemplate());
        entity.setColumnDef(dto.getColumnDef());
        entity.setFilterDef(dto.getFilterDef());
        entity.setStatus(dto.getStatus());
        entity.setRemark(dto.getRemark());
        entity.setUpdatedTime(LocalDateTime.now());

        reportDefMapper.updateById(entity);
    }

    /**
     * Delete report definition (soft delete)
     *
     * @param id report ID
     */
    @Transactional
    public void delete(Long id) {
        RptReportDef entity = reportDefMapper.selectById(id);
        if (entity == null || Boolean.TRUE.equals(entity.getDeleted())) {
            throw new BusinessException(404, "Report definition not found");
        }

        entity.setDeleted(true);
        entity.setUpdatedTime(LocalDateTime.now());
        reportDefMapper.updateById(entity);
    }

    /**
     * Validate SQL query template for security
     *
     * @param queryTemplate SQL query template
     */
    private void validateQueryTemplate(String queryTemplate) {
        if (queryTemplate == null || queryTemplate.trim().isEmpty()) {
            throw new BusinessException(400, "Query template cannot be empty");
        }

        String upper = queryTemplate.toUpperCase();

        // Forbidden write operation keywords (case-insensitive, word boundary matching)
        List<String> forbidden = List.of("INSERT", "UPDATE", "DELETE", "DROP", "TRUNCATE", "ALTER", "CREATE", "GRANT", "REVOKE");
        for (String keyword : forbidden) {
            // Use regex word boundary to prevent false positives (e.g., "INSERTED_AT" should not trigger "INSERT")
            if (Pattern.compile("\\b" + keyword + "\\b").matcher(upper).find()) {
                throw new BusinessException(400, "SQL template cannot contain write operation keyword: " + keyword);
            }
        }

        // Forbid ${} direct concatenation
        if (queryTemplate.contains("${")) {
            throw new BusinessException(400, "SQL template cannot use ${} placeholders, please use #{}");
        }

        // Forbid multi-statement (semicolon separated)
        String trimmed = queryTemplate.trim();
        if (trimmed.contains(";") && !trimmed.endsWith(";")) {
            throw new BusinessException(400, "SQL template cannot contain multiple statements");
        }

        // Forbid comments (to prevent bypassing detection)
        if (queryTemplate.contains("--") || queryTemplate.contains("/*")) {
            throw new BusinessException(400, "SQL template cannot contain comments");
        }

        // Forbid manual tenant_id condition (to prevent bypassing tenant isolation)
        if (upper.contains("TENANT_ID")) {
            throw new BusinessException(400, "SQL template cannot manually specify tenant_id condition");
        }
    }
}

