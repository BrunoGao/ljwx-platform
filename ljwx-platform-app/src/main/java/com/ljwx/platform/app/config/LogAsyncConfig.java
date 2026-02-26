package com.ljwx.platform.app.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * 日志异步写入线程池配置。
 *
 * <p>为 {@link com.ljwx.platform.app.appservice.OperationLogAppService#saveOperationLog}
 * 的 {@code @Async("logTaskExecutor")} 提供专用线程池，避免日志写入阻塞业务线程。
 *
 * <p>规格（spec/phase/phase-09.md）：core=2, max=4, queue=1024。
 */
@Configuration("phase09LogAsyncConfig")
@EnableAsync
public class LogAsyncConfig {
}
