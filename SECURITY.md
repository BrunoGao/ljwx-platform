# Security Policy

## Supported Versions

Only actively maintained branches are supported for security fixes:

- `main`
- `master` (if still used for release flow)

## Reporting A Vulnerability

Do not open public issues for undisclosed vulnerabilities.

Use one of the following private channels:

1. GitHub Security Advisory (preferred)
2. Maintainer security contact in organization settings

Include as much detail as possible:

- affected component and version/commit
- reproduction steps or proof of concept
- impact assessment (confidentiality/integrity/availability)
- suggested mitigation (if any)

## Response Targets

- Initial acknowledgement: within 2 business days
- Triage and severity assignment: within 5 business days
- Mitigation plan: as soon as validated

## Security Baseline In This Repository

- Dependabot for dependency update PRs
- CodeQL for static application security testing
- Secret scanning workflow on pull requests and pushes
- SBOM generation workflow for release traceability
- Required status checks and branch protection on protected branches
