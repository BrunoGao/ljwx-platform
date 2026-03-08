package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.JobCreateDTO;
import com.ljwx.platform.app.domain.dto.JobQueryDTO;
import com.ljwx.platform.app.domain.dto.JobUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysJob;
import com.ljwx.platform.app.infra.mapper.SysJobMapper;
import com.ljwx.platform.app.infra.quartz.QuartzJobDispatcher;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.quartz.CronScheduleBuilder;
import org.quartz.CronTrigger;
import org.quartz.JobBuilder;
import org.quartz.JobDetail;
import org.quartz.JobKey;
import org.quartz.Scheduler;
import org.quartz.SchedulerException;
import org.quartz.TriggerBuilder;
import org.quartz.TriggerKey;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 定时任务应用服务。
 *
 * <p>每个任务在 Quartz 中以 per-tenant JobKey 注册：
 * {@code JobKey(name="{jobId}", group="TENANT_{tenantId}")}
 */
@Service
@RequiredArgsConstructor
public class JobAppService {

    private final SysJobMapper jobMapper;
    private final Scheduler scheduler;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder tenantHolder;

    public PageResult<SysJob> listJobs(JobQueryDTO query) {
        SysJob filter = new SysJob();
        filter.setJobName(query.getJobName());
        filter.setStatus(query.getStatus());
        List<SysJob> records = jobMapper.selectList(filter);
        long total = jobMapper.countList(filter);
        return new PageResult<>(records, total);
    }

    public SysJob getJobById(Long id) {
        SysJob job = jobMapper.selectById(id);
        if (job == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "任务不存在");
        }
        return job;
    }

    @Transactional
    public Long createJob(JobCreateDTO dto) throws SchedulerException {
        long id = idGenerator.nextId();
        Long tenantId = tenantHolder.getTenantId();

        SysJob job = new SysJob();
        job.setId(id);
        job.setJobName(dto.getJobName());
        job.setJobGroup(dto.getJobGroup() != null ? dto.getJobGroup() : "DEFAULT");
        job.setJobClassName(dto.getJobClassName());
        job.setCronExpression(dto.getCronExpression());
        job.setDescription(dto.getDescription());
        job.setStatus(1);
        jobMapper.insert(job);

        // Per-tenant JobKey: name="{jobId}", group="TENANT_{tenantId}"
        JobKey jobKey = new JobKey(String.valueOf(id), "TENANT_" + tenantId);
        JobDetail jobDetail = JobBuilder.newJob(QuartzJobDispatcher.class)
                .withIdentity(jobKey)
                .usingJobData("jobClassName", dto.getJobClassName())
                .storeDurably()
                .build();
        CronTrigger trigger = TriggerBuilder.newTrigger()
                .withIdentity(String.valueOf(id), "TENANT_" + tenantId)
                .withSchedule(CronScheduleBuilder.cronSchedule(dto.getCronExpression()))
                .build();
        scheduler.scheduleJob(jobDetail, trigger);
        return id;
    }

    @Transactional
    public void updateJob(JobUpdateDTO dto) throws SchedulerException {
        Long tenantId = tenantHolder.getTenantId();

        SysJob existing = getJobById(dto.getId());
        existing.setJobName(dto.getJobName());
        if (dto.getJobGroup() != null) {
            existing.setJobGroup(dto.getJobGroup());
        }
        existing.setJobClassName(dto.getJobClassName());
        existing.setCronExpression(dto.getCronExpression());
        existing.setDescription(dto.getDescription());
        existing.setVersion(dto.getVersion());
        jobMapper.updateById(existing);

        // Reschedule Quartz trigger with new cron expression
        TriggerKey triggerKey = new TriggerKey(String.valueOf(dto.getId()), "TENANT_" + tenantId);
        CronTrigger newTrigger = TriggerBuilder.newTrigger()
                .withIdentity(triggerKey)
                .withSchedule(CronScheduleBuilder.cronSchedule(dto.getCronExpression()))
                .build();
        scheduler.rescheduleJob(triggerKey, newTrigger);
    }

    public void executeNow(Long id) throws SchedulerException {
        Long tenantId = tenantHolder.getTenantId();
        JobKey jobKey = new JobKey(String.valueOf(id), "TENANT_" + tenantId);
        scheduler.triggerJob(jobKey);
    }

    @Transactional
    public void pauseJob(Long id) throws SchedulerException {
        Long tenantId = tenantHolder.getTenantId();
        JobKey jobKey = new JobKey(String.valueOf(id), "TENANT_" + tenantId);
        scheduler.pauseJob(jobKey);

        SysJob job = getJobById(id);
        job.setStatus(0);
        jobMapper.updateById(job);
    }

    @Transactional
    public void resumeJob(Long id) throws SchedulerException {
        Long tenantId = tenantHolder.getTenantId();
        JobKey jobKey = new JobKey(String.valueOf(id), "TENANT_" + tenantId);
        scheduler.resumeJob(jobKey);

        SysJob job = getJobById(id);
        job.setStatus(1);
        jobMapper.updateById(job);
    }

    @Transactional
    public void deleteJob(Long id) throws SchedulerException {
        Long tenantId = tenantHolder.getTenantId();
        getJobById(id);
        scheduler.deleteJob(new JobKey(String.valueOf(id), "TENANT_" + tenantId));
        jobMapper.deleteById(id);
    }
}
