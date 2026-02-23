package com.ljwx.platform.web.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Spring MVC configuration for the LJWX platform.
 *
 * <p>Key settings:
 * <ul>
 *   <li>CORS — allows all origins with credentials for {@code /api/**} endpoints,
 *       supporting the Admin, Mobile, and Screen frontends running on different ports
 *       during development.</li>
 * </ul>
 *
 * <p>Note: Spring Security's CORS support takes precedence for authenticated
 * endpoints. This configurer covers the MVC layer (e.g., pre-flight OPTIONS
 * requests and public endpoints not handled by the security filter chain).
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    /**
     * Configures CORS for all {@code /api/**} paths.
     *
     * <ul>
     *   <li>{@code allowedOriginPatterns("*")} — permits any origin while still
     *       supporting {@code allowCredentials(true)}.</li>
     *   <li>Allowed methods: GET, POST, PUT, DELETE, PATCH, OPTIONS.</li>
     *   <li>Allowed headers: all.</li>
     *   <li>Max age: 3600 seconds (1 hour) for preflight cache.</li>
     * </ul>
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
}
