package com.ljwx.platform.app;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * LJWX Platform — Spring Boot application entry point.
 *
 * <p>Component scan is rooted at {@code com.ljwx.platform} so that all
 * {@code @Configuration}, {@code @Component}, {@code @Service}, and
 * {@code @Repository} beans defined across the core, security, data, and web
 * modules are discovered automatically.
 *
 * <p>Key capabilities enabled here:
 * <ul>
 *   <li>{@code @EnableCaching} — activates Caffeine-backed Spring Cache for
 *       dict and config data (TTL = 10 min, see application.yml).</li>
 *   <li>{@code @EnableAsync} — enables Spring's async task execution, used
 *       by the operation-log service to record audit logs on a dedicated
 *       thread pool (core=2, max=4, queue=1024).</li>
 *   <li>{@code @MapperScan} — registers all MyBatis mapper interfaces in both
 *       infra and legacy app mapper packages with the SqlSessionFactory.</li>
 * </ul>
 */
@SpringBootApplication(scanBasePackages = "com.ljwx.platform")
@EnableCaching
@EnableAsync
@MapperScan({"com.ljwx.platform.app.infra.mapper", "com.ljwx.platform.app.mapper"})
public class LjwxPlatformApplication {

    public static void main(String[] args) {
        SpringApplication.run(LjwxPlatformApplication.class, args);
    }
}
