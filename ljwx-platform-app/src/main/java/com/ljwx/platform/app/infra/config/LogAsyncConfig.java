package com.ljwx.platform.app.infra.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

/**
 * 操作日志异步线程池配置。
 *
 * <p>规格（spec/01-constraints.md §操作日志）：
 * core size = 2, max size = 4, queue capacity = 1024。
 * OperationLogAppService 的异步保存方法使用 {@code @Async("logTaskExecutor")} 声明。
 */
@Configuration
public class LogAsyncConfig {

    /**
     * 操作日志专用线程池。
     *
     * @return 已配置的 {@link ThreadPoolTaskExecutor}
     */
    @Bean("logTaskExecutor")
    public Executor logTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(1024);
        executor.setThreadNamePrefix("log-async-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(10);
        executor.initialize();
        return executor;
    }
}
