package com.ljwx.platform.security.filter;

import com.ljwx.platform.security.blacklist.TokenBlacklistService;
import com.ljwx.platform.security.jwt.JwtTokenProvider;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Stateless JWT authentication filter.
 *
 * <p>Executed once per request. Extracts the Bearer token from the
 * {@code Authorization} header, validates it, and — for access tokens only —
 * populates the {@link SecurityContextHolder} with an authenticated
 * {@link UsernamePasswordAuthenticationToken}.
 *
 * <p>The {@code details} map attached to the token contains:
 * <ul>
 *   <li>{@code "userId"}   — Long</li>
 *   <li>{@code "tenantId"} — Long</li>
 *   <li>{@code "username"} — String</li>
 * </ul>
 * These values are read by {@link com.ljwx.platform.security.context.SecurityContextUserHolder}
 * and {@link com.ljwx.platform.security.context.SecurityContextTenantHolder}.
 *
 * <p>Refresh tokens are deliberately rejected here; they are only accepted at
 * {@code /api/auth/refresh} which handles its own token validation.
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtTokenProvider jwtTokenProvider;
    private final TokenBlacklistService tokenBlacklistService;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String token = extractToken(request);

        if (token != null && jwtTokenProvider.isTokenValid(token)) {
            try {
                Claims claims = jwtTokenProvider.parseToken(token);

                // Only access tokens are valid for general API requests.
                // Refresh tokens must only be used at /api/auth/refresh.
                if (jwtTokenProvider.isAccessToken(claims)) {
                    // Reject blacklisted tokens (e.g., after logout)
                    String jti = jwtTokenProvider.getJti(claims);
                    if (jti != null && tokenBlacklistService.isBlacklisted(jti)) {
                        SecurityContextHolder.clearContext();
                        filterChain.doFilter(request, response);
                        return;
                    }
                    List<String> rawAuthorities = jwtTokenProvider.getAuthorities(claims);
                    List<SimpleGrantedAuthority> grantedAuthorities = rawAuthorities.stream()
                            .map(SimpleGrantedAuthority::new)
                            .toList();

                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(
                                    jwtTokenProvider.getUsername(claims),
                                    null,
                                    grantedAuthorities);

                    Map<String, Object> details = new HashMap<>();
                    details.put("userId", jwtTokenProvider.getUserId(claims));
                    details.put("tenantId", jwtTokenProvider.getTenantId(claims));
                    details.put("username", jwtTokenProvider.getUsername(claims));
                    authentication.setDetails(details);

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (JwtException e) {
                // Invalid or tampered token — clear context so the request stays unauthenticated.
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Extracts the raw JWT string from the {@code Authorization: Bearer <token>} header.
     *
     * @return the token string, or {@code null} if the header is absent or malformed
     */
    private String extractToken(HttpServletRequest request) {
        String header = request.getHeader(AUTHORIZATION_HEADER);
        if (header != null && header.startsWith(BEARER_PREFIX)) {
            return header.substring(BEARER_PREFIX.length());
        }
        return null;
    }
}
