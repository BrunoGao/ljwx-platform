package com.ljwx.platform.data.config;

import org.springframework.context.annotation.Configuration;

/**
 * MyBatis configuration for the LJWX Platform data module.
 *
 * <h3>Interceptor Registration</h3>
 * <p>{@code AuditFieldInterceptor} and {@code TenantLineInterceptor} are annotated with
 * {@code @Component} and implement MyBatis {@code Interceptor}.
 * Spring Boot's {@code MybatisAutoConfiguration} auto-detects all {@code Interceptor}
 * beans in the application context and registers them with the {@code SqlSessionFactory}
 * — no explicit registration is needed in this class.
 *
 * <h3>Mapper Scanning</h3>
 * <p>{@code @MapperScan} is intentionally absent here.
 * The data module must not reference application-layer packages
 * (DAG rule: {@code core ← data ← app}).
 * The {@code app} module is responsible for configuring {@code @MapperScan}
 * against its own {@code infra.mapper} package.
 *
 * <h3>Future Extensions</h3>
 * <p>Custom {@code TypeHandler}s, {@code TypeAlias}es, and global MyBatis settings
 * (e.g., map-underscore-to-camel-case) may be added here as the platform grows.
 */
@Configuration
public class MyBatisConfig {
    // Interceptors are auto-registered by Spring Boot's MybatisAutoConfiguration.
    // See AuditFieldInterceptor and TenantLineInterceptor for implementation details.
}
