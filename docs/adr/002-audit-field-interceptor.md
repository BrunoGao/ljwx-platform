# ADR-002: Audit Field Interceptor Strategy

**Status:** Accepted
**Date:** 2026-02-23
**Deciders:** Platform Architecture Team

## Context

All business tables require 7 audit columns: `tenant_id`, `created_by`, `created_time`, `updated_by`, `updated_time`, `deleted`, `version`. These must be populated automatically without requiring callers to set them manually, and without exposing them in DTOs.

## Decision

We use a **MyBatis Interceptor** (`AuditFieldInterceptor`) in the `ljwx-platform-data` module to automatically populate audit fields on INSERT and UPDATE operations.

### How it works

1. `AuditFieldInterceptor` intercepts `Executor.update()` (covers both INSERT and UPDATE).
2. On INSERT: sets `created_by`, `created_time`, `updated_by`, `updated_time`, `tenant_id`, `deleted=false`, `version=1`.
3. On UPDATE: sets `updated_by`, `updated_time`, increments `version`.
4. User ID is read from `CurrentUserHolder.getUserId()` — a `core` interface implemented by `SecurityContextUserHolder` in the `security` module.
5. Tenant ID is read from `CurrentTenantHolder.getTenantId()` — a `core` interface implemented by `SecurityContextTenantHolder`.

### Why MyBatis Interceptor (not AOP)

- Works at the SQL execution level, not the service level — catches all writes regardless of call path.
- No need to annotate every service method.
- Compatible with both `@Mapper` and XML-based mappers.

### Column defaults as safety net

All 7 audit columns have `NOT NULL DEFAULT` in DDL. This means even if the interceptor is bypassed (e.g., direct SQL, test data), the database will not reject the insert.

## Consequences

- **Positive:** Zero boilerplate in service/controller code for audit fields.
- **Positive:** Consistent audit trail across all business tables.
- **Positive:** `tenant_id` is never in DTOs — enforced by `gate-rules.sh` R06.
- **Negative:** Interceptor must be carefully maintained to handle all entity types.
- **Enforcement:** `gate-rules.sh` R05 verifies all business table DDL contains all 7 audit columns.

## Alternatives Considered

- **Spring AOP `@Before` advice:** Rejected — requires annotating every service method, easy to miss.
- **BaseEntity with `@PrePersist`/`@PreUpdate`:** Rejected — project uses MyBatis, not JPA.
- **Manual setting in each service:** Rejected — error-prone, violates DRY.
