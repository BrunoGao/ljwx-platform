# ADR-005: Platform Changelog

**Status:** Living Document
**Date:** 2026-02-23

This document records significant architectural and implementation decisions made during the platform build, organized by phase.

---

## Phase 0 — Skeleton (2026-02-23)

- Established Maven multi-module parent POM with Spring Boot 3.5.11 BOM.
- Established pnpm workspace with Node 22.22.0 and pnpm 10.30.1.
- Created gate system: `gate-all.sh`, `gate-compile.sh`, `gate-manifest.sh`, `gate-rules.sh`, `gate-nfr.sh`, `gate-contract.sh`, `gate-integration.sh`.
- Established Claude Code hooks: `pre-edit-guard.sh` (path-level blocking), `post-edit-check.sh` (content-level checks), `stop-gate.sh` (phase completion validation).
- Decision: Use POSIX ERE (`grep -E`) throughout all shell scripts for macOS BSD grep compatibility. No `grep -P`.

## Phase 1 — Core Module (2026-02-23)

- Implemented `Result<T>`, `ErrorCode`, `PageResult<T>` as the universal API response envelope.
- Implemented `SnowflakeIdGenerator` for distributed ID generation.
- Defined `CurrentUserHolder` and `CurrentTenantHolder` interfaces — the DAG boundary contracts.
- Implemented `BaseEntity` with all 7 audit fields.

## Phase 2 — Data Module (2026-02-23)

- Implemented `AuditFieldInterceptor` (MyBatis) for automatic audit field population.
- Implemented `TenantLineInterceptor` (MyBatis) for automatic `WHERE tenant_id = ?` injection.
- Both interceptors depend only on `core` interfaces, not `security` — DAG preserved.

## Phase 3 — Security Module (2026-02-23)

- Implemented JWT-based stateless authentication with HS256.
- Custom `JwtAuthenticationConverter` reads `authorities` claim without prefix.
- `SecurityContextUserHolder` and `SecurityContextTenantHolder` implement `core` interfaces.
- Access token: 30 min. Refresh token: 7 days.

## Phase 4 — Web Module (2026-02-23)

- Implemented `GlobalExceptionHandler` with structured error responses.
- Implemented `ResponseAdvice` for automatic `Result<T>` wrapping.
- `WebMvcConfig` configures CORS and static resource handling.

## Phase 5 — App Skeleton (2026-02-23)

- Created `LjwxPlatformApplication` with `@SpringBootApplication`.
- Created Flyway migrations V001–V009: schema init, user/role/permission tables, seed data.
- Admin password `Admin@12345` stored as BCrypt cost=10 hash in V006.
- Decision: Flyway migrations never use `IF NOT EXISTS` — version numbers guarantee idempotency.

## Phase 6 — AI Context Docs (2026-02-23)

- Created `CLAUDE.md` as the single source of truth for hard rules and version locks.
- Created `spec/` directory with architecture, constraints, API, database, config, and devops specs.
- Created `.claude/rules/` for conditional context rules loaded by Claude Code.

## Phase 7 — Quartz Integration (2026-02-23)

- Integrated `spring-boot-starter-quartz` for scheduled job management.
- Quartz tables created via V010 (standard QRTZ_ prefix, no audit columns — Quartz system tables).
- `sys_job` table created via V011 (has all 7 audit columns).
- Per-tenant job isolation: `JobKey(name="{jobId}", group="TENANT_{tenantId}")`.

## Phase 8 — Dict and Config (2026-02-23)

- Implemented `sys_dict_type`, `sys_dict_data`, `sys_config` tables.
- Dict and config use Caffeine JVM cache with 10-minute TTL.
- No Redis dependency — keeps infrastructure simple.

## Phase 9 — Logs, Notice, File (2026-02-23)

- Implemented operation log with async thread pool (core=2, max=4, queue=1024).
- Log body truncated at 4096 bytes. Sensitive fields masked: password→`***`, phone→middle 4 `*`, idCard→middle segment `*`.
- File upload: 50 MB limit, whitelist of allowed extensions, Snowflake ID naming.
- Notice system for system-wide announcements.

## Phase 10 — Index and Contract (2026-02-23)

- Added database indexes via V021 for performance on common query patterns.
- Created `export-openapi.sh` for OpenAPI JSON export.
- Created `docs/contracts/` directory for API contract storage.

## Phase 11 — Shared Package (2026-02-23)

- Created `packages/shared` TypeScript package with `tsup` build.
- Shared types: `Result<T>`, `PageResult<T>`, `UserVO`, `RoleVO`, `PermissionVO`, etc.
- Shared constants: error codes, permission strings.
- All three frontend apps depend on `@ljwx/shared`.

## Phase 12 — Admin Scaffold (2026-02-23)

- Created Vue 3 admin app with Vite 7, TypeScript 5.9, Element Plus 2.13.
- Vue Router 5 (not v4) — uses `createRouter` with v5 API.
- Pinia 3 for state management.
- `unplugin-auto-import` and `unplugin-vue-components` for DX.

## Phase 13 — Admin CRUD Pages (2026-02-24)

- Implemented all system management pages: user, role, tenant, dict, config, job, file, notice.
- Implemented monitor pages: operation log, login log.
- All API calls typed with `@ljwx/shared` types.

## Phase 14 — Admin Permission and Polish (2026-02-24)

- Implemented route guards with JWT token validation.
- Implemented permission store with dynamic route loading.
- Added Breadcrumb, TagsView, ThemeSwitch components.
- `usePermission` composable for `v-if` permission checks.

## Phase 15 — Mobile Scaffold (2026-02-24)

- Created uni-app mobile project with Vue 3 + TypeScript.
- Login, home, work, message, mine pages.
- Pinia store for user state.

## Phase 16 — Mobile Feature Pages (2026-02-24)

- Implemented work, message, mine pages with API integration.
- Notice list and user profile pages.

## Phase 17 — Screen Scaffold (2026-02-24)

- Created Vue 3 data screen app with ECharts 6.
- `useScreenAdapt` composable for responsive scaling.
- Dark theme configuration for ECharts.
- `ScreenLayout` with full-screen support.

## Phase 18 — Screen Components (2026-02-24)

- Implemented 11 chart components: Bar, Line, Pie, Radar, Gauge, Scatter, Map, Funnel, Heatmap, Treemap, Sankey.
- Implemented DataV-style components: WaterBall, Ring.
- Implemented widget components: NumberFlip, ScrollTable.
- Home dashboard view integrating all components.

## Phase 20 — Menu Management and Dynamic Routes (planned)

- Backend: `sys_menu` table (V022) with tree structure (parent_id, menu_type: directory/menu/button).
- Seed data (V023): system management directory and all sub-menus mapped to existing RBAC permission strings.
- API: `/api/v1/menus` CRUD + `/api/v1/menus/tree` returning nested tree.
- Frontend: `src/stores/menu.ts` for menu tree state, `src/views/system/menu/index.vue` with el-table tree mode.
- New permissions: `system:menu:list/detail/create/update/delete`.

## Phase 21 — Department Management and Data Scope (planned)

- Backend: `sys_dept` table (V024) with tree structure, seed default root department (V025).
- API: `/api/v1/depts` CRUD + `/api/v1/depts/tree`.
- `DataScopeInterceptor` in `ljwx-platform-data` module — appends `dept_id IN (...)` condition based on data_scope value passed via ThreadLocal (no security package import, DAG preserved).
- Data scope levels: ALL / TENANT / DEPT_AND_CHILDREN / DEPT / SELF.
- Frontend: `src/views/system/dept/index.vue` with el-tree display.

## Phase 22 — Profile, Login Log and Online Users (planned)

- Login log: `sys_login_log` table (V026), async write on login success/failure (reuses existing LogAsyncConfig thread pool).
- Profile API: `GET/PUT /api/v1/profile`, `PUT /api/v1/profile/password` — authenticated but no @PreAuthorize (JWT auth sufficient).
- Online users: Caffeine-backed token registry (key=jti, TTL=access token expiry). `DELETE /api/v1/online-users/{tokenId}` for force-kickout.
- Password fields masked in logs: `***`.

## Phase 23 — Admin Frontend Pages Batch 2 (planned)

- New pages: dept tree management, menu tree management, personal profile center, login log list, online user list with force-kickout.
- All pages follow existing style conventions from Phase 13.
- API modules: `dept.ts`, `profile.ts`, `loginLog.ts`, `onlineUser.ts`.

## Phase 24 — Tenant Package, Notice Read and Import/Export (planned)

- Tenant package: `sys_tenant_package` table (V027), `sys_tenant` gains `package_id` FK. Defines menu set and resource quotas (max users, max storage MB).
- Notice read status: `sys_notice_user` table (V028). `PUT /api/v1/notices/{id}/read` and `GET /api/v1/notices/unread-count`.
- Import/Export: `GET /api/v1/users/export` and `POST /api/v1/users/import` using Apache POI or EasyExcel.

## Phase 25 — System Monitor, Rate Limit and WebSocket (planned)

- Monitor: `GET /api/v1/monitor/server|jvm|cache` using `ManagementFactory` — no extra dependencies.
- Rate limit: `@RateLimit` annotation + `RateLimitInterceptor` in web module, Caffeine token bucket, SpEL key expressions.
- WebSocket: `/ws/notifications` endpoint, JWT validation on connect, `userId → WebSocketSession` map for targeted push.
- `useWebSocket.ts` composable in admin frontend with auto-reconnect.

## Phase 26 — Integration Tests Phase 2 (planned)

- Integration tests for all Phase 20–25 controllers using Testcontainers PostgreSQL.
- Coverage: 401 unauthenticated, 403 unauthorized, full CRUD flow, parameter validation.
- Reuses test infrastructure from Phase 18.

## Phase 27 — Final Gate and Full Manifest v2 (planned)

- Update `FULL_MANIFEST.txt` to include all Phase 20–27 files.
- Update `README.md` with new feature descriptions.
- All 6 gates must pass: manifest, rules, compile, integration, contract, NFR.

