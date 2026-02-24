package com.ljwx.platform.security.config;

import com.ljwx.platform.security.filter.JwtAuthenticationFilter;
import com.ljwx.platform.security.jwt.JwtProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Spring Security configuration for the LJWX platform.
 *
 * <p>Key decisions:
 * <ul>
 *   <li>Stateless session — no HTTP session is ever created or used.</li>
 *   <li>CSRF disabled — safe for a stateless REST API protected by JWT bearer tokens.</li>
 *   <li>{@code /api/auth/login} and {@code /api/auth/refresh} are publicly accessible
 *       (no authentication required) so clients can obtain tokens.</li>
 *   <li>All other endpoints require authentication.</li>
 *   <li>Fine-grained access control is enforced per method via
 *       {@code @PreAuthorize("hasAuthority('resource:action')")}.</li>
 *   <li>BCrypt cost factor is 10 as required by the LJWX platform standard.</li>
 * </ul>
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@EnableConfigurationProperties(JwtProperties.class)
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    /**
     * Main security filter chain.
     *
     * <p>Public endpoints:
     * <ul>
     *   <li>{@code POST /api/auth/login} — obtains access + refresh tokens</li>
     *   <li>{@code POST /api/auth/refresh} — exchanges a refresh token for a new access token</li>
     * </ul>
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/login", "/api/auth/refresh").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        .anyRequest().authenticated())
                .addFilterBefore(jwtAuthenticationFilter,
                        UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * Password encoder — BCrypt with cost factor 10 (LJWX platform standard).
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(10);
    }
}
