# ADR-006: Security Hardening

## Status

Accepted

## Context

As the LJWX Platform evolves into a production-ready system, we need comprehensive security measures beyond basic JWT authentication. Modern web applications face multiple attack vectors including XSS, CSRF, replay attacks, and brute-force login attempts. Without proper hardening, the platform remains vulnerable to common security threats.

## Decision

We implement a multi-layered security hardening strategy covering four key areas:

### 1. XSS Protection

**Implementation**: `XssFilter` + `XssHttpServletRequestWrapper`

- Filter order: `Ordered.HIGHEST_PRECEDENCE + 1` (runs after TraceIdFilter)
- Sanitizes all request parameters, headers, and body content
- Uses OWASP Java HTML Sanitizer library
- Whitelist approach: allows only safe HTML tags and attributes
- Applied globally to all HTTP requests

**Rationale**: XSS attacks can steal user sessions, inject malicious scripts, and compromise user data. Input sanitization at the filter level provides defense-in-depth before data reaches application logic.

### 2. Idempotency Token

**Implementation**: `@Idempotent` annotation + `IdempotentInterceptor`

- Token format: `UUID` stored in Redis with 5-minute TTL
- Client workflow:
  1. GET `/api/v1/idempotent/token` → receives token
  2. Include token in `X-Idempotent-Token` header for POST/PUT/DELETE
  3. Server validates and consumes token (one-time use)
- Prevents duplicate submissions and replay attacks

**Rationale**: Network retries and user double-clicks can cause duplicate operations (e.g., double payment, duplicate order creation). Idempotency tokens ensure each critical operation executes exactly once.

### 3. JWT Blacklist

**Implementation**: `TokenBlacklistService`

- Redis-based blacklist with TTL matching token expiration
- Logout operation adds token to blacklist
- `JwtAuthenticationFilter` checks blacklist before accepting token
- Supports forced logout for security incidents

**Rationale**: Standard JWT cannot be revoked before expiration. Blacklist enables immediate token invalidation for logout, password changes, and security breaches.

### 4. Login Lockout

**Implementation**: `LoginLockoutService`

- Tracks failed login attempts per username in Redis
- Lockout policy:
  - 5 failed attempts → 15-minute lockout
  - Counter resets on successful login
  - Lockout duration increases exponentially for repeated violations
- Returns `423 Locked` status during lockout period

**Rationale**: Brute-force attacks can compromise weak passwords. Rate limiting login attempts significantly increases attack cost and provides time for security monitoring to detect threats.

### 5. Strong Password Validation

**Implementation**: `@StrongPassword` annotation + `StrongPasswordValidator`

- Enforces password complexity:
  - Minimum 8 characters
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one digit
  - At least one special character
- Applied to password fields in DTOs

**Rationale**: Weak passwords are the primary entry point for account compromise. Enforcing strong password policies reduces the risk of brute-force and dictionary attacks.

## Consequences

### Positive

- **Defense in Depth**: Multiple security layers protect against different attack vectors
- **Compliance Ready**: Meets common security standards (OWASP Top 10, PCI DSS)
- **Audit Trail**: All security events (lockouts, token invalidation) are logged
- **User Experience**: Idempotency prevents frustrating duplicate operations
- **Incident Response**: JWT blacklist enables immediate threat mitigation

### Negative

- **Redis Dependency**: Security features require Redis availability
- **Performance Overhead**: XSS sanitization adds ~2-5ms per request
- **Client Complexity**: Idempotency requires client-side token management
- **Storage Cost**: Blacklist and lockout data consume Redis memory

### Mitigation

- Redis clustering for high availability
- XSS filter only processes text content (skips binary uploads)
- Idempotency is optional (only for critical operations)
- Redis TTL ensures automatic cleanup of security data

## Alternatives Considered

### 1. WAF (Web Application Firewall)

- **Pros**: Centralized security, no code changes
- **Cons**: Additional infrastructure cost, configuration complexity
- **Decision**: Implement application-level security first, WAF as optional enhancement

### 2. CSRF Tokens

- **Pros**: Standard protection for form submissions
- **Cons**: Stateful, complex for SPA/mobile clients
- **Decision**: Use SameSite cookies + custom headers instead (covered in JWT implementation)

### 3. Rate Limiting at API Gateway

- **Pros**: Offloads rate limiting from application
- **Cons**: Less granular control, requires gateway infrastructure
- **Decision**: Implement both (application-level for login, gateway-level for DDoS)

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Java HTML Sanitizer](https://github.com/OWASP/java-html-sanitizer)
- [RFC 7231 - HTTP Idempotency](https://datatracker.ietf.org/doc/html/rfc7231#section-4.2.2)
- Phase 28 Implementation: `spec/phase/phase-28.md`

## Related ADRs

- ADR-003: JWT Authorities Convention
- ADR-007: Observability (TraceId for security event correlation)
