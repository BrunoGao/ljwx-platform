package com.ljwx.platform.app.filter;

import com.ljwx.platform.core.context.CurrentTenantHolder;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Tenant metrics filter for recording request metrics.
 *
 * <p>This filter implements a three-tier metrics strategy:
 * <ul>
 *   <li><b>L1 (Low Cardinality)</b>: Global metrics written to Prometheus (JVM, HTTP status codes)</li>
 *   <li><b>L2 (Tenant Dimension)</b>: Tenant-specific metrics written to Loki as JSON log fields</li>
 *   <li><b>L3 (Precise Stats)</b>: Detailed statistics written to PostgreSQL for billing</li>
 * </ul>
 *
 * <p><b>IMPORTANT</b>: Tenant ID is NEVER used as a Prometheus label (high cardinality violation).
 * Tenant-level metrics are logged to Loki and queried via LogQL aggregations.
 *
 * <p>Complies with {@code spec/registry/observability.yml} constraints:
 * <ul>
 *   <li>Prometheus labels: status, method, uri (low cardinality only)</li>
 *   <li>Loki labels: level, app (whitelist only)</li>
 *   <li>Tenant ID: JSON field in Loki logs, not a label</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TenantMetricsFilter extends OncePerRequestFilter {

    private final MeterRegistry meterRegistry;
    private final CurrentTenantHolder tenantHolder;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                   HttpServletResponse response,
                                   FilterChain filterChain) throws ServletException, IOException {
        long startTime = System.nanoTime();

        try {
            filterChain.doFilter(request, response);
        } finally {
            long duration = System.nanoTime() - startTime;
            double durationMs = duration / 1_000_000.0;

            // Extract tenant ID (may be null for public endpoints)
            Long tenantId = tenantHolder.getTenantId();
            String uri = request.getRequestURI();
            int status = response.getStatus();

            // L2: Log tenant-specific metrics to Loki (JSON fields, not labels)
            // These logs are queried via LogQL for tenant-level aggregations
            // Example LogQL: {app="ljwx-platform"} | json | t_id="123" | stats avg(duration_ms) by (path)
            if (tenantId != null) {
                log.info("tenant_request t_id={} path={} status={} duration_ms={}",
                        tenantId, uri, status, String.format("%.2f", durationMs));
            }

            // L1: Record global metrics to Prometheus (low cardinality labels only)
            // CRITICAL: Do NOT add tenant_id as a label (high cardinality violation)
            recordGlobalMetrics(uri, status, duration);
        }
    }

    /**
     * Records global metrics to Prometheus with low cardinality labels.
     *
     * <p>Labels used:
     * <ul>
     *   <li>status: HTTP status code (limited set: 2xx, 3xx, 4xx, 5xx)</li>
     *   <li>uri: Request URI (limited to route templates, not actual paths)</li>
     * </ul>
     *
     * <p><b>FORBIDDEN</b>: tenant_id, user_id, or any high-cardinality dimension.
     */
    private void recordGlobalMetrics(String uri, int status, long durationNanos) {
        // Normalize URI to reduce cardinality (e.g., /api/v1/users/123 -> /api/v1/users/{id})
        String normalizedUri = normalizeUri(uri);

        // Record request count
        Counter.builder("http_requests_total")
                .tag("status", String.valueOf(status))
                .tag("uri", normalizedUri)
                .description("Total HTTP requests")
                .register(meterRegistry)
                .increment();

        // Record request duration
        Timer.builder("http_request_duration_seconds")
                .tag("status", String.valueOf(status))
                .tag("uri", normalizedUri)
                .description("HTTP request duration in seconds")
                .register(meterRegistry)
                .record(durationNanos, java.util.concurrent.TimeUnit.NANOSECONDS);
    }

    /**
     * Normalizes URI to reduce cardinality by replacing numeric IDs with placeholders.
     *
     * <p>Examples:
     * <ul>
     *   <li>/api/v1/users/123 → /api/v1/users/{id}</li>
     *   <li>/api/v1/depts/456/users/789 → /api/v1/depts/{id}/users/{id}</li>
     * </ul>
     */
    private String normalizeUri(String uri) {
        if (uri == null) {
            return "unknown";
        }
        // Replace numeric path segments with {id}
        return uri.replaceAll("/\\d+", "/{id}");
    }
}

