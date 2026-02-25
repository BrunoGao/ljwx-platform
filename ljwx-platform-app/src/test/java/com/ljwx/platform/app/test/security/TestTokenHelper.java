package com.ljwx.platform.app.test.security;

import com.ljwx.platform.security.jwt.JwtProperties;
import com.ljwx.platform.security.jwt.JwtTokenProvider;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.UUID;

/**
 * Test token helper that reuses production JWT claims/signature conventions.
 */
@Component
public class TestTokenHelper {

    private final JwtTokenProvider jwtTokenProvider;
    private final JwtProperties jwtProperties;

    public TestTokenHelper(JwtTokenProvider jwtTokenProvider, JwtProperties jwtProperties) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.jwtProperties = jwtProperties;
    }

    public String generateToken(String username,
                                Long tenantId,
                                List<String> permissions,
                                long expiresInSeconds) {
        return generateToken(1L, username, tenantId, permissions, expiresInSeconds);
    }

    public String generateToken(Long userId,
                                String username,
                                Long tenantId,
                                List<String> permissions,
                                long expiresInSeconds) {
        if (expiresInSeconds == jwtProperties.getAccessTokenExpiration()) {
            return jwtTokenProvider.createAccessToken(userId, tenantId, username, permissions);
        }
        Instant now = Instant.now();
        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .subject(String.valueOf(userId))
                .claim("tenantId", tenantId)
                .claim("username", username)
                .claim("type", "access")
                .claim("authorities", permissions)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(expiresInSeconds)))
                .signWith(signingKey(), Jwts.SIG.HS256)
                .compact();
    }

    public String adminTenantA() {
        return generateToken(
                1L,
                "admin",
                1L,
                List.of(
                        "user:read",
                        "user:write",
                        "user:delete",
                        "role:read",
                        "role:write",
                        "role:delete",
                        "dict:read",
                        "dict:write",
                        "config:read",
                        "config:write",
                        "system:menu:list",
                        "system:menu:detail",
                        "system:menu:create",
                        "system:menu:update",
                        "system:menu:delete"
                ),
                jwtProperties.getAccessTokenExpiration());
    }

    public String adminTenantB() {
        return generateToken(
                20001L,
                "tenant_b_admin",
                2L,
                List.of("user:read", "system:menu:list"),
                jwtProperties.getAccessTokenExpiration());
    }

    public String userTenantA() {
        return generateToken(
                1L,
                "admin",
                1L,
                List.of("user:read", "system:menu:list"),
                jwtProperties.getAccessTokenExpiration());
    }

    public String noPerm() {
        return generateToken(
                1L,
                "admin",
                1L,
                List.of(),
                jwtProperties.getAccessTokenExpiration());
    }

    public String expiredToken() {
        return generateToken(
                1L,
                "admin",
                1L,
                List.of("user:read"),
                -60L);
    }

    private SecretKey signingKey() {
        byte[] keyBytes = jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
