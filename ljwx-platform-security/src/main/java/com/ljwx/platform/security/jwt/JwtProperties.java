package com.ljwx.platform.security.jwt;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * JWT configuration properties.
 *
 * <p>Bound from {@code application.yml} prefix {@code ljwx.jwt}.
 * A placeholder secret must be overridden via the {@code ljwx.jwt.secret} environment variable
 * before deploying to any non-local environment.
 */
@Data
@Component
@ConfigurationProperties(prefix = "ljwx.jwt")
public class JwtProperties {

    /**
     * HMAC-SHA256 signing secret. Must be at least 32 characters.
     * Override in production via environment variable / vault.
     */
    private String secret = "change-me-in-production-must-be-32-chars!!";

    /**
     * Access token expiration in seconds. Default: 1800 (30 minutes).
     */
    private long accessTokenExpiration = 1800L;

    /**
     * Refresh token expiration in seconds. Default: 604800 (7 days).
     */
    private long refreshTokenExpiration = 604800L;
}
