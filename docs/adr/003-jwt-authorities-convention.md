# ADR-003: JWT Authorities Convention

**Status:** Accepted
**Date:** 2026-02-23
**Deciders:** Platform Architecture Team

## Context

Spring Security's default JWT support uses the `scope` or `scp` claim for authorities, and automatically adds a `SCOPE_` prefix. The platform uses a custom RBAC model with `resource:action` permission strings (e.g., `user:read`, `role:write`). Using Spring's defaults would require either stripping prefixes everywhere or using non-standard claim names.

## Decision

We use a **custom `authorities` claim** in the JWT payload and a **custom `JwtAuthenticationConverter`** that reads this claim directly without adding any prefix.

### JWT Payload Structure

```json
{
  "sub": "1001",
  "tenantId": 1,
  "username": "admin",
  "type": "access",
  "authorities": ["user:read", "user:write", "role:read", "role:write"],
  "iat": 1700000000,
  "exp": 1700001800
}
```

### Custom Converter

```java
JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
converter.setJwtGrantedAuthoritiesConverter(jwt -> {
    List<String> authorities = jwt.getClaimAsStringList("authorities");
    return authorities.stream()
        .map(SimpleGrantedAuthority::new)  // no prefix added
        .collect(Collectors.toList());
});
```

### Controller Usage

```java
@PreAuthorize("hasAuthority('user:read')")
```

NOT:
```java
@PreAuthorize("hasRole('ADMIN')")  // FORBIDDEN — no ROLE_ prefix
```

### Token Types

- `type: "access"` — short-lived (30 min), used for API calls.
- `type: "refresh"` — long-lived (7 days), used only for `/api/auth/refresh`.
- The `JwtAuthenticationFilter` rejects refresh tokens on non-refresh endpoints.

## Consequences

- **Positive:** Permission strings are human-readable (`user:read` vs `SCOPE_user:read`).
- **Positive:** No prefix stripping needed in `@PreAuthorize` expressions.
- **Positive:** `tenantId` in JWT enables stateless multi-tenancy without database lookup per request.
- **Negative:** Custom converter must be maintained; Spring Security upgrades may require review.
- **Enforcement:** `gate-rules.sh` R07 verifies every `@*Mapping` method has `@PreAuthorize`. R11 checks for deprecated ROLE_ usage.

## Alternatives Considered

- **Spring default `scope` claim:** Rejected — adds `SCOPE_` prefix, incompatible with `resource:action` format.
- **Database session for permissions:** Rejected — adds latency, breaks stateless design.
- **Opaque tokens with introspection:** Rejected — requires token introspection endpoint, adds complexity.
