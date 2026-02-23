package com.ljwx.platform.app.infra.quartz;

import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;

/**
 * Generic Quartz job dispatcher.
 *
 * <p>Reads the target class name from {@code JobDataMap} key {@code "jobClassName"},
 * instantiates it via reflection, and invokes it as a {@link Runnable}.
 * The actual job implementations must have a no-arg constructor and implement
 * {@link Runnable}.
 *
 * <p>JobKey format: name="{jobId}", group="TENANT_{tenantId}"
 */
public class QuartzJobDispatcher implements Job {

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        String jobClassName = context.getJobDetail().getJobDataMap().getString("jobClassName");
        if (jobClassName == null || jobClassName.isBlank()) {
            throw new JobExecutionException("jobClassName is missing from JobDataMap");
        }
        try {
            Class<?> clazz = Class.forName(jobClassName);
            Runnable task = (Runnable) clazz.getDeclaredConstructor().newInstance();
            task.run();
        } catch (ClassCastException e) {
            throw new JobExecutionException("Job class must implement Runnable: " + jobClassName, e);
        } catch (Exception e) {
            throw new JobExecutionException("Failed to dispatch job: " + jobClassName, e);
        }
    }
}
