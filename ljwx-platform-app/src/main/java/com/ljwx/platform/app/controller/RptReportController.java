package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.report.ReportDefCreateDTO;
import com.ljwx.platform.app.dto.report.ReportDefQueryDTO;
import com.ljwx.platform.app.dto.report.ReportDefUpdateDTO;
import com.ljwx.platform.app.dto.report.ReportExecuteDTO;
import com.ljwx.platform.app.service.RptReportDefAppService;
import com.ljwx.platform.app.service.RptReportExecuteService;
import com.ljwx.platform.app.vo.report.ReportDefVO;
import com.ljwx.platform.app.vo.report.ReportResultVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Report Controller
 */
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class RptReportController {

    private final RptReportDefAppService reportDefAppService;
    private final RptReportExecuteService reportExecuteService;

    /**
     * Query report definition list with pagination
     *
     * @param query query conditions
     * @return paginated report definition list
     */
    @PreAuthorize("hasAuthority('report:def:list')")
    @GetMapping
    public Result<PageResult<ReportDefVO>> list(ReportDefQueryDTO query) {
        PageResult<ReportDefVO> result = reportDefAppService.list(query);
        return Result.ok(result);
    }

    /**
     * Get report definition by ID
     *
     * @param id report ID
     * @return report definition VO
     */
    @PreAuthorize("hasAuthority('report:def:query')")
    @GetMapping("/{id}")
    public Result<ReportDefVO> getById(@PathVariable Long id) {
        ReportDefVO vo = reportDefAppService.getById(id);
        return Result.ok(vo);
    }

    /**
     * Create report definition
     *
     * @param dto create DTO
     * @return report ID
     */
    @PreAuthorize("hasAuthority('report:def:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody ReportDefCreateDTO dto) {
        Long id = reportDefAppService.create(dto);
        return Result.ok(id);
    }

    /**
     * Update report definition
     *
     * @param id report ID
     * @param dto update DTO
     * @return success result
     */
    @PreAuthorize("hasAuthority('report:def:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody ReportDefUpdateDTO dto) {
        reportDefAppService.update(id, dto);
        return Result.ok();
    }

    /**
     * Delete report definition (soft delete)
     *
     * @param id report ID
     * @return success result
     */
    @PreAuthorize("hasAuthority('report:def:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        reportDefAppService.delete(id);
        return Result.ok();
    }

    /**
     * Execute report query
     *
     * @param id report ID
     * @param dto execute DTO
     * @return report result
     */
    @PreAuthorize("hasAuthority('report:def:execute')")
    @PostMapping("/{id}/execute")
    public Result<ReportResultVO> execute(@PathVariable Long id, @Valid @RequestBody ReportExecuteDTO dto) {
        ReportResultVO result = reportExecuteService.execute(id, dto);
        return Result.ok(result);
    }
}
