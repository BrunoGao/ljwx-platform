package com.ljwx.platform.security.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.List;

/**
 * JWT token provider — creates and validates HS256-signed tokens.
 *
 * <p>Payload claims:
 * <ul>
 *   <li>{@code sub} — userId (String)</li>
 *   <li>{@code tenantId} — tenant ID (Long)</li>
 *   <li>{@code username} — login name (String)</li>
 *   <li>{@code type} — "access" | "refresh"</li>
 *   <li>{@code authorities} — list of permission strings, e.g. "user:read"</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class JwtTokenProvider {

    private final JwtProperties jwtProperties;

    // ─────────────────────────────── token creation ────────────────────────────────

    /**
     * Creates a short-lived access token (default 30 min).
     */
    public String createAccessToken(Long userId, Long tenantId, String username,
                                    List<String> authorities) {
        return buildToken(userId, tenantId, username, "access", authorities,
                jwtProperties.getAccessTokenExpiration());
    }

    /**
     * Creates a long-lived refresh token (default 7 days).
     */
    public String createRefreshToken(Long userId, Long tenantId, String username,
                                     List<String> authorities) {
        return buildToken(userId, tenantId, username, "refresh", authorities,
                jwtProperties.getRefreshTokenExpiration());
    }

    private String buildToken(Long userId, Long tenantId, String username,
                               String type, List<String> authorities,
                               long expirationSeconds) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("tenantId", tenantId)
                .claim("username", username)
                .claim("type", type)
                .claim("authorities", authorities)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(expirationSeconds)))
                .signWith(signingKey(), Jwts.SIG.HS256)
                .compact();
    }

    // ─────────────────────────────── token parsing ─────────────────────────────────

    /**
     * Parses and validates the token, returning its claims payload.
     *
     * @param token raw JWT string (without "Bearer " prefix)
     * @return verified {@link Claims}
     * @throws JwtException if the token is invalid or expired
     */
    public Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(signingKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Returns {@code true} if the token signature and expiry are valid.
     */
    public boolean isTokenValid(String token) {
        try {
            parseToken(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    // ─────────────────────────────── claim accessors ────────────────────────────────

    /**
     * Returns {@code true} when the {@code type} claim equals "access".
     */
    public boolean isAccessToken(Claims claims) {
        return "access".equals(claims.get("type", String.class));
    }

    /**
     * Extracts the {@code sub} claim as a {@code Long} userId.
     */
    public Long getUserId(Claims claims) {
        return Long.parseLong(claims.getSubject());
    }

    /**
     * Extracts the {@code tenantId} claim, handling both Integer and Long from JSON.
     */
    public Long getTenantId(Claims claims) {
        Object raw = claims.get("tenantId");
        if (raw instanceof Long l) return l;
        if (raw instanceof Integer i) return i.longValue();
        if (raw instanceof Number n) return n.longValue();
        return null;
    }

    /**
     * Extracts the {@code username} claim.
     */
    public String getUsername(Claims claims) {
        return claims.get("username", String.class);
    }

    /**
     * Extracts the {@code authorities} claim as a list of permission strings.
     */
    @SuppressWarnings("unchecked")
    public List<String> getAuthorities(Claims claims) {
        Object raw = claims.get("authorities");
        if (raw instanceof List<?> list) {
            return (List<String>) list;
        }
        return List.of();
    }

    // ─────────────────────────────── internal ──────────────────────────────────────

    private SecretKey signingKey() {
        byte[] keyBytes = jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
