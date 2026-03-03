package com.ljwx.platform.app.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ljwx.platform.app.domain.RptReportDef;
import com.ljwx.platform.app.dto.report.ReportDefQueryDTO;
import com.ljwx.platform.app.vo.report.ReportDefVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * Report Definition Mapper
 */
@Mapper
public interface RptReportDefMapper extends BaseMapper<RptReportDef> {

    /**
     * Query report definition list
     *
     * @param query query conditions
     * @return report definition list
     */
    List<ReportDefVO> selectReportDefList(@Param("query") ReportDefQueryDTO query);

    /**
     * Count report definitions
     *
     * @param query query conditions
     * @return total count
     */
    long countReportDefs(@Param("query") ReportDefQueryDTO query);

    /**
     * Get report definition by ID
     *
     * @param id report ID
     * @return report definition VO
     */
    ReportDefVO selectReportDefById(@Param("id") Long id);

    /**
     * Check if report key exists in tenant
     *
     * @param tenantId tenant ID
     * @param reportKey report key
     * @param excludeId exclude this ID (for update check)
     * @return count
     */
    int countByReportKey(@Param("tenantId") Long tenantId,
                         @Param("reportKey") String reportKey,
                         @Param("excludeId") Long excludeId);
}
