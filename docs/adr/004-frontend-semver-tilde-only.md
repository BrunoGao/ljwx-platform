# ADR-004: Frontend Semver Tilde-Only Policy

**Status:** Accepted
**Date:** 2026-02-23
**Deciders:** Platform Architecture Team

## Context

npm/pnpm package.json supports two common version range operators:
- `^` (caret): allows minor and patch updates (e.g., `^1.2.3` matches `1.x.x`)
- `~` (tilde): allows patch updates only (e.g., `~1.2.3` matches `1.2.x`)

Using caret ranges means a `pnpm install` on a fresh machine can pull in a different minor version than what was tested, potentially introducing breaking changes silently.

## Decision

All frontend `dependencies` and `devDependencies` in every `package.json` in this repository **must use tilde (`~`) ranges only**. Caret (`^`) is forbidden.

### Rationale

1. **Reproducibility:** Tilde ensures only patch-level updates are auto-applied. Minor version bumps (which may contain breaking changes) require explicit human decision.
2. **Vue ecosystem stability:** Vue 3, Vue Router 5, Pinia, and Element Plus have had minor-version breaking changes. Tilde prevents accidental upgrades.
3. **pnpm lockfile:** Even with a lockfile, the range in `package.json` matters for `pnpm update` and fresh installs without a lockfile.
4. **Audit trail:** Upgrading a minor version requires a deliberate `package.json` edit, which appears in git history.

### Scope

Applies to:
- `ljwx-platform-admin/package.json`
- `ljwx-platform-screen/package.json`
- `ljwx-platform-mobile/package.json`
- `packages/shared/package.json`
- Root `package.json`

### Example

```json
{
  "dependencies": {
    "vue": "~3.5.28",
    "vue-router": "~5.0.2",
    "pinia": "~3.0.4",
    "element-plus": "~2.13.2",
    "axios": "~1.13.5"
  }
}
```

NOT:
```json
{
  "dependencies": {
    "vue": "^3.5.28"  // FORBIDDEN
  }
}
```

## Consequences

- **Positive:** Deterministic builds across environments.
- **Positive:** Breaking changes from minor version bumps are caught before they reach CI.
- **Negative:** Requires manual `package.json` edits to get minor version updates.
- **Enforcement:** `gate-rules.sh` R01 scans all `package.json` files for caret ranges and fails the gate if any are found.

## Alternatives Considered

- **Exact versions (no range):** Too strict — prevents security patch auto-application.
- **Caret ranges:** Rejected — too permissive, risk of silent breaking changes.
- **Lockfile only:** Insufficient — lockfile can be regenerated, losing the intent.
