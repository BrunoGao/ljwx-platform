# GitHub Labels And Issues Governance

## Phase Epic Rule

- Each phase must have one `Phase Epic` issue.
- Title convention: `[Phase XX] <summary>`.
- Label convention: `phase-XX`.
- Project fields should include at least `Phase`, `Workflow`, `Priority`, `Gate Status`.

## Spec / Issue / PR Linkage

- Every implementation PR must reference its phase spec file (`spec/phase/phase-XX.md`).
- Every Phase Epic issue must include `Spec Link` in issue body.
- PR description must reference closing or related issue (`Closes #...`, `Relates #...`).
- If a PR changes scope, update both spec and Phase Epic in the same PR.

## Test Campaign Governance

- Full baseline/regression work must be tracked by `test-campaign` issues.
- Suite-specific work uses `test-suite` issues.
- Coverage gap backlogs use `test-debt` issues.
- Regression failures use `regression-bug` issues and must include run URL.

## Regression Run Record

For each regression run:

1. Attach run URL to campaign issue.
2. Record gate outcome and key failures.
3. Open/refresh regression bug issues for failed cases.
4. Update `Gate Status` for impacted phase epics.

## Labels (Compatibility Layer)

Labels are secondary metadata for search and back-compat:

- Phase: `phase-00` ... `phase-32`
- Workflow: `workflow:brief/spec/coding/gate/review/done`
- Priority: `priority:P0/P1/P2`
- Optional: `suite:*`, `workstream:*`, `gate:*`

Project fields remain the primary source of truth for dashboards and automation.
