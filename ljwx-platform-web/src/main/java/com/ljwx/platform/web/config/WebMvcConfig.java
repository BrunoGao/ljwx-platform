package com.ljwx.platform.web.config;

import com.ljwx.platform.web.interceptor.IdempotentInterceptor;
import com.ljwx.platform.web.interceptor.RateLimitInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Spring MVC configuration for the LJWX platform.
 *
 * <p>Key settings:
 * <ul>
 *   <li>CORS — allows all origins with credentials for {@code /api/**} endpoints.</li>
 *   <li>RateLimitInterceptor — enforces per-key rate limits on methods annotated
 *       with {@link com.ljwx.platform.web.annotation.RateLimit}.</li>
 * </ul>
 */
@Configuration
@RequiredArgsConstructor
public class WebMvcConfig implements WebMvcConfigurer {

    private final RateLimitInterceptor rateLimitInterceptor;
    private final IdempotentInterceptor idempotentInterceptor;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(rateLimitInterceptor).addPathPatterns("/api/**");
        registry.addInterceptor(idempotentInterceptor).addPathPatterns("/api/**");
    }
}

