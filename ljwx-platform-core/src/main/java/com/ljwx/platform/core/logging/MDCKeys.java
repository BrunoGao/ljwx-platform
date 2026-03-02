package com.ljwx.platform.core.logging;

/**
 * MDC (Mapped Diagnostic Context) key constants for structured logging.
 *
 * <p>These keys are used to inject contextual information into log entries,
 * enabling efficient querying and filtering in log aggregation systems like Loki.
 *
 * <p><strong>Important:</strong> These values are stored as JSON fields in log entries,
 * NOT as Loki labels. High-cardinality fields like {@code trace_id}, {@code tenant_id},
 * and {@code user_id} should remain as JSON fields to avoid label cardinality issues.
 */
public final class MDCKeys {

    /**
     * Unique trace ID for request correlation (16-character hex string).
     * JSON field, not a Loki label.
     */
    public static final String TRACE_ID = "trace_id";

    /**
     * Tenant ID for multi-tenant isolation.
     * JSON field, not a Loki label.
     */
    public static final String TENANT_ID = "tenant_id";

    /**
     * User ID of the authenticated user.
     * JSON field, not a Loki label.
     */
    public static final String USER_ID = "user_id";

    /**
     * HTTP request URI (e.g., "/api/v1/users").
     */
    public static final String REQUEST_URI = "requestUri";

    /**
     * HTTP request method (e.g., "GET", "POST").
     */
    public static final String REQUEST_METHOD = "requestMethod";

    /**
     * Client IP address (supports X-Forwarded-For).
     */
    public static final String CLIENT_IP = "clientIp";

    private MDCKeys() {
        throw new UnsupportedOperationException("Utility class");
    }
}
