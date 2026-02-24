# ADR-001: Module Dependency DAG

**Status:** Accepted
**Date:** 2026-02-23
**Deciders:** Platform Architecture Team

## Context

The LJWX Platform is a multi-module Maven project. Without explicit dependency rules, modules can develop circular or inappropriate dependencies that make the codebase hard to maintain, test, and reason about.

## Decision

We enforce a strict directed acyclic graph (DAG) for module dependencies:

```
core  ←  security
core  ←  data
security + data  ←  web
web + data  ←  app
```

Concrete rules:

| Module | Allowed direct dependencies |
|--------|-----------------------------|
| `ljwx-platform-core` | None (only external libs) |
| `ljwx-platform-security` | `core` |
| `ljwx-platform-data` | `core` |
| `ljwx-platform-web` | `security` (core via transitive) |
| `ljwx-platform-app` | `web` + `data` (security + core via transitive) |

**Critical constraint:** `security` and `data` are siblings — they must NOT import from each other. Both depend only on `core` interfaces (`CurrentUserHolder`, `CurrentTenantHolder`). At runtime, Spring DI wires the `security` implementations into `data` interceptors.

## Consequences

- **Positive:** Clear separation of concerns. `data` module can be tested without Spring Security on the classpath. `security` module can be tested without MyBatis.
- **Positive:** Prevents accidental coupling between authentication logic and data access logic.
- **Negative:** Requires discipline — developers must not add cross-sibling imports.
- **Enforcement:** `gate-rules.sh` R10 scans all Java files for DAG violations on every gate run.

## Alternatives Considered

- **Single module:** Rejected — too large, no separation of concerns.
- **security depends on data:** Rejected — creates circular dependency risk and couples auth to persistence.
- **Hexagonal architecture with ports/adapters:** Considered for future, current DAG is sufficient for the platform's scale.
