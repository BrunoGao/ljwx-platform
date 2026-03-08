package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.JobAppService;
import com.ljwx.platform.app.domain.dto.JobCreateDTO;
import com.ljwx.platform.app.domain.dto.JobQueryDTO;
import com.ljwx.platform.app.domain.dto.JobUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysJob;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.quartz.SchedulerException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 定时任务管理 Controller。
 * 权限按 spec/03-api.md §Jobs 路由定义。
 */
@RestController
@RequestMapping({"/api/v1/jobs", "/api/jobs"})
@RequiredArgsConstructor
public class JobController {

    private final JobAppService jobAppService;

    @PreAuthorize("hasAuthority('job:read')")
    @GetMapping
    public Result<PageResult<SysJob>> list(JobQueryDTO query) {
        return Result.ok(jobAppService.listJobs(query));
    }

    @PreAuthorize("hasAuthority('job:write')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid JobCreateDTO dto) throws SchedulerException {
        return Result.ok(jobAppService.createJob(dto));
    }

    @PreAuthorize("hasAuthority('job:read')")
    @GetMapping("/{id}")
    public Result<SysJob> detail(@PathVariable Long id) {
        return Result.ok(jobAppService.getJobById(id));
    }

    @PreAuthorize("hasAuthority('job:write')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid JobUpdateDTO dto) throws SchedulerException {
        dto.setId(id);
        jobAppService.updateJob(dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('job:execute')")
    @PostMapping({"/{id}/execute", "/{id}/run"})
    public Result<Void> execute(@PathVariable Long id) throws SchedulerException {
        jobAppService.executeNow(id);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('job:write')")
    @PostMapping("/{id}/pause")
    public Result<Void> pause(@PathVariable Long id) throws SchedulerException {
        jobAppService.pauseJob(id);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('job:write')")
    @PostMapping("/{id}/resume")
    public Result<Void> resume(@PathVariable Long id) throws SchedulerException {
        jobAppService.resumeJob(id);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('job:write')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) throws SchedulerException {
        jobAppService.deleteJob(id);
        return Result.ok();
    }
}
