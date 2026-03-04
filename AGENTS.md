# Repository Guidelines

## Project Structure & Module Organization
This repository is a mixed Java + frontend monorepo.
- Backend modules (Maven multi-module): `ljwx-platform-core`, `ljwx-platform-security`, `ljwx-platform-data`, `ljwx-platform-web`, `ljwx-platform-app`.
- Backend code: `*/src/main/java`; backend tests: `*/src/test/java`; DB migrations: `ljwx-platform-app/src/main/resources/db/migration`.
- Frontend apps: `ljwx-platform-admin`, `ljwx-platform-mobile`, `ljwx-platform-screen`; shared TS package: `packages/shared`.
- System tests and performance scripts: `tests/e2e`, `tests/perf`.
- Operational and CI scripts: `scripts/gates`, `scripts/ci`, `scripts/ops`.

## Build, Test, and Development Commands
- `./mvnw clean package -DskipTests`: build backend artifacts quickly.
- `mvn -B -ntp -q test -f pom.xml`: run Java unit/component tests.
- `mvn verify -f pom.xml`: run full Maven verification (includes integration flow when available).
- `pnpm dev:admin` / `pnpm dev:mobile` / `pnpm dev:screen`: run frontend apps in dev mode.
- `pnpm build:all`: build shared package and all frontend apps.
- `bash scripts/gates/gate-all.sh <phase>` (example: `bash scripts/gates/gate-all.sh 27`): run unified quality gates.
- `bash scripts/ci/lint-shell.sh && bash scripts/ci/lint-yaml.sh`: validate shell and YAML files before PR.

## Coding Style & Naming Conventions
- Follow `.editorconfig`: 2 spaces by default, 4 spaces for `*.java` and `*.xml`, LF endings, UTF-8.
- Java package naming follows `com.ljwx.platform...`; keep classes in clear domain-oriented packages.
- Test class naming: `*Test.java` (unit/component), `*IT.java` (integration).
- Keep scripts and branch names descriptive: `feature/*`, `fix/*`, `chore/*`, `hotfix/*`.

## Testing Guidelines
- Primary backend framework: JUnit via Maven Surefire/Failsafe.
- E2E and perf are k6-based scripts under `tests/e2e` and `tests/perf`.
- For behavior changes, include or update tests and provide evidence in PR (logs, gate output, or report paths).

## Commit & Pull Request Guidelines
- Prefer Conventional Commits, as seen in history: `feat(ci): ...`, `fix(ci): ...`, `chore(github): ...`.
- Avoid non-informative messages like `wip`, `merge`, or `commit all`.
- PRs should include: linked issue (`Closes #...`/`Relates #...`), phase/spec reference, test evidence, and changelog/docs updates when behavior changes.
- Ensure CODEOWNERS review and passing checks before merge.

## Security & Configuration Tips
- Do not commit secrets. Start from `.env.example` and keep local values in `.env`.
- Follow `SECURITY.md` for vulnerability reporting and handling.
