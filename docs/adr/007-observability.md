# ADR-007: Observability — TraceId, Structured Logging, Slow API Monitoring

## Status

Accepted

## Context

Production systems require comprehensive observability to diagnose issues, monitor performance, and understand user behavior. Traditional text-based logs are difficult to parse, correlate across services, and query efficiently. Without distributed tracing, debugging multi-step operations becomes nearly impossible. Performance degradation often goes unnoticed until users complain.

## Decision

We implement a three-pillar observability strategy:

### 1. Distributed Tracing with TraceId

**Implementation**: `TraceIdFilter`

- Filter order: `Ordered.HIGHEST_PRECEDENCE` (runs first)
- TraceId generation:
  - Check `X-Trace-Id` request header
  - If present: use provided value (for cross-service correlation)
  - If absent: generate UUID and take first 16 characters
- MDC (Mapped Diagnostic Context) population:
  - `traceId`: request correlation ID
  - `tenantId`: from SecurityContext (if authenticated)
  - `userId`: from SecurityContext (if authenticated)
- Response header: `X-Trace-Id` echoed back to client
- Cleanup: `MDC.clear()` in finally block to prevent thread pool pollution

**Rationale**: TraceId enables end-to-end request tracking across logs, metrics, and traces. MDC automatically includes context in every log statement without code changes.

### 2. Structured JSON Logging

**Implementation**: `logback-spring.xml`

- Production format: JSON with fields:
  ```json
  {
    "time": "2026-03-01T10:30:45.123Z",
    "level": "INFO",
    "traceId": "a1b2c3d4e5f6g7h8",
    "tenantId": 1,
    "userId": 100,
    "logger": "com.ljwx.platform.app.controller.UserController",
    "thread": "http-nio-8080-exec-5",
    "message": "User created successfully",
    "exception": "..."
  }
  ```
- Development format: Human-readable with colors
- Log levels:
  - ERROR: Exceptions, critical failures
  - WARN: Slow APIs, deprecated usage, recoverable errors
  - INFO: Business events (login, CRUD operations)
  - DEBUG: Detailed flow (disabled in production)

**Rationale**: JSON logs are machine-parseable, enabling efficient querying in log aggregation systems (ELK, Loki). Structured fields support filtering, aggregation, and correlation without regex parsing.

### 3. Slow API Monitoring

**Implementation**: `SlowApiAspect`

- AOP pointcut: All `@RestController` methods
- Thresholds:
  - **WARN**: Execution time ≥ 3000ms
  - **ERROR**: Execution time ≥ 10000ms
- Log format:
  ```
  WARN [traceId=abc123] Slow API detected: GET /api/v1/users took 3500ms
  ERROR [traceId=def456] Very slow API: POST /api/v1/orders took 12000ms
  ```
- Includes: HTTP method, path, execution time, traceId

**Rationale**: Proactive performance monitoring catches degradation before it impacts users. Automatic logging eliminates manual instrumentation. TraceId correlation enables root cause analysis.

### 4. Frontend Error Reporting

**Implementation**: `useErrorMonitor.ts` + `FrontendErrorController`

- Client-side monitoring:
  - Captures `window.onerror` (JavaScript errors)
  - Captures `unhandledrejection` (Promise rejections)
  - Debouncing: Same error message only reported once per 5 seconds
- Error payload:
  ```typescript
  {
    errorMessage: string,
    stackTrace: string,
    pageUrl: string,
    userAgent: string
  }
  ```
- Server endpoint: `POST /api/v1/frontend-errors`
- Storage: `sys_frontend_error` table with 7 audit fields

**Rationale**: Frontend errors are invisible to backend monitoring. Centralized error collection enables proactive bug fixing and user experience improvement.

## Consequences

### Positive

- **Rapid Debugging**: TraceId links logs across components for single request
- **Performance Visibility**: Slow API alerts catch regressions immediately
- **Queryable Logs**: JSON structure enables complex queries (e.g., "all errors for tenant 5 in last hour")
- **Cross-Team Collaboration**: Shared traceId between frontend and backend teams
- **Proactive Monitoring**: Automated alerts for slow APIs and frontend errors

### Negative

- **Log Volume**: JSON logs are ~30% larger than text logs
- **MDC Overhead**: ThreadLocal operations add ~0.1ms per request
- **Storage Cost**: Structured logs require more disk/cloud storage
- **Learning Curve**: Developers must understand MDC and structured logging

### Mitigation

- Log rotation and compression (gzip) reduce storage by 80%
- MDC cleanup in finally block prevents memory leaks
- Development environment uses human-readable format
- Documentation and examples for common logging patterns

## Implementation Details

### TraceId Propagation

```java
// Client sends request with traceId
GET /api/v1/users
X-Trace-Id: abc123def456

// Server processes and returns same traceId
HTTP/1.1 200 OK
X-Trace-Id: abc123def456

// All logs include traceId
{"time":"...", "traceId":"abc123def456", "message":"User query executed"}
```

### Slow API Detection

```java
@Aspect
@Component
public class SlowApiAspect {
    @Around("@within(org.springframework.web.bind.annotation.RestController)")
    public Object monitor(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.currentTimeMillis();
        try {
            return pjp.proceed();
        } finally {
            long duration = System.currentTimeMillis() - start;
            if (duration >= 10000) {
                log.error("Very slow API: {} took {}ms", path, duration);
            } else if (duration >= 3000) {
                log.warn("Slow API detected: {} took {}ms", path, duration);
            }
        }
    }
}
```

### Frontend Error Monitoring

```typescript
// useErrorMonitor.ts
export function useErrorMonitor() {
  const errorCache = new Map<string, number>();

  window.onerror = (message, source, lineno, colno, error) => {
    const key = String(message);
    const now = Date.now();
    const lastReport = errorCache.get(key) || 0;

    if (now - lastReport > 5000) { // 5 second debounce
      reportError({ errorMessage: key, stackTrace: error?.stack, ... });
      errorCache.set(key, now);
    }
  };
}
```

## Alternatives Considered

### 1. OpenTelemetry

- **Pros**: Industry standard, vendor-neutral, rich ecosystem
- **Cons**: Complex setup, requires collector infrastructure
- **Decision**: Start with simple TraceId + MDC, migrate to OpenTelemetry when scaling to microservices

### 2. APM Tools (New Relic, Datadog)

- **Pros**: Turnkey solution, advanced analytics, alerting
- **Cons**: High cost ($100-500/host/month), vendor lock-in
- **Decision**: Use open-source stack (ELK/Loki) for cost control, APM as optional enhancement

### 3. Metrics-Only Approach (Prometheus)

- **Pros**: Low overhead, efficient storage
- **Cons**: No request-level detail, difficult to debug specific issues
- **Decision**: Use both logs (debugging) and metrics (alerting)

## Integration with Monitoring Stack

### Recommended Stack

- **Logs**: Loki (Grafana) or Elasticsearch
- **Metrics**: Prometheus
- **Traces**: Jaeger or Tempo (future)
- **Dashboards**: Grafana

### Query Examples

```promql
# Loki: Find all slow APIs for tenant 5
{app="ljwx-platform"} |= "Slow API" | json | tenantId="5"

# Loki: Trace specific request
{app="ljwx-platform"} | json | traceId="abc123def456"

# Prometheus: API latency P99
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

## References

- [The Twelve-Factor App: Logs](https://12factor.net/logs)
- [Grafana Loki Best Practices](https://grafana.com/docs/loki/latest/best-practices/)
- [MDC in SLF4J](http://www.slf4j.org/manual.html#mdc)
- Phase 29 Implementation: `spec/phase/phase-29.md`

## Related ADRs

- ADR-006: Security Hardening (TraceId for security event correlation)
- ADR-008: Data Change Audit (audit logs use same structured format)
