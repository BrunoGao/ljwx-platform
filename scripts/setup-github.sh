#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=true
PHASE_RANGE=""
GATE_RULESET=""
REPORT_PATH="docs/reports/"
ARCHITECT_TEAM="@org/architects"
SECURITY_TEAM="@org/security"
DBA_TEAM="@org/dba"
PRODUCT_TEAM="@org/product"
OFFICIAL_ONLY="true"
INIT_MILESTONES="false"

usage() {
  cat <<USAGE
Usage: scripts/setup-github.sh [options]

Options:
  --dry-run                     Print commands only (default)
  --apply                       Execute commands
  --phase-range <start-end>     Example: 20-27
  --gate-ruleset <value>        Example: R01-R09
  --report-path <path>          Default: docs/reports/
  --architect-team <team>       Default: @org/architects
  --security-team <team>        Default: @org/security
  --dba-team <team>             Default: @org/dba
  --product-team <team>         Default: @org/product
  --official-only <true|false>  Default: true
  --init-milestones             Optional module C (default: off)
  -h, --help                    Show help
USAGE
}

print_cmd() {
  printf '[dry-run] '
  printf '%q ' "$@"
  echo
}

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI not found. Install: https://cli.github.com/" >&2
    exit 1
  fi
}

detect_phase_range() {
  local max_phase=""
  if [[ -d spec/phase ]]; then
    max_phase="$(find spec/phase -maxdepth 1 -type f -name 'phase-*.md' -printf '%f\n' 2>/dev/null \
      | sed -E 's/^phase-([0-9]{2})\.md$/\1/' \
      | sort -n \
      | tail -n1 || true)"
  fi

  if [[ -n "$max_phase" ]]; then
    PHASE_RANGE="00-$((10#$max_phase))"
  else
    PHASE_RANGE="00-53"
  fi
}

detect_gate_ruleset() {
  if [[ -f scripts/gates/gate-rules.sh ]]; then
    if grep -q 'R01' scripts/gates/gate-rules.sh && grep -q 'R09' scripts/gates/gate-rules.sh; then
      GATE_RULESET="R01-R09"
      return
    fi
  fi
  GATE_RULESET="R01-R09"
}

detect_repo() {
  local origin
  origin="$(git config --get remote.origin.url 2>/dev/null || true)"

  case "$origin" in
    git@github.com:*.git)
      REPO="${origin#git@github.com:}"
      REPO="${REPO%.git}"
      ;;
    https://github.com/*/*.git)
      REPO="${origin#https://github.com/}"
      REPO="${REPO%.git}"
      ;;
    https://github.com/*/*)
      REPO="${origin#https://github.com/}"
      ;;
    *)
      REPO=""
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --apply)
      DRY_RUN=false
      shift
      ;;
    --phase-range)
      PHASE_RANGE="${2:?missing value for --phase-range}"
      shift 2
      ;;
    --gate-ruleset)
      GATE_RULESET="${2:?missing value for --gate-ruleset}"
      shift 2
      ;;
    --report-path)
      REPORT_PATH="${2:?missing value for --report-path}"
      shift 2
      ;;
    --architect-team)
      ARCHITECT_TEAM="${2:?missing value for --architect-team}"
      shift 2
      ;;
    --security-team)
      SECURITY_TEAM="${2:?missing value for --security-team}"
      shift 2
      ;;
    --dba-team)
      DBA_TEAM="${2:?missing value for --dba-team}"
      shift 2
      ;;
    --product-team)
      PRODUCT_TEAM="${2:?missing value for --product-team}"
      shift 2
      ;;
    --official-only)
      OFFICIAL_ONLY="${2:?missing value for --official-only}"
      shift 2
      ;;
    --init-milestones)
      INIT_MILESTONES="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_gh

if [[ -z "$PHASE_RANGE" ]]; then
  detect_phase_range
fi
if [[ -z "$GATE_RULESET" ]]; then
  detect_gate_ruleset
fi

if ! [[ "$PHASE_RANGE" =~ ^([0-9]{1,2})-([0-9]{1,2})$ ]]; then
  echo "Invalid PHASE_RANGE: $PHASE_RANGE (expected start-end, e.g. 20-27)" >&2
  exit 1
fi

START_PHASE="${BASH_REMATCH[1]}"
END_PHASE="${BASH_REMATCH[2]}"
START_PHASE=$((10#$START_PHASE))
END_PHASE=$((10#$END_PHASE))

if (( END_PHASE < START_PHASE )); then
  echo "Invalid PHASE_RANGE: end < start" >&2
  exit 1
fi

if [[ "$OFFICIAL_ONLY" != "true" && "$OFFICIAL_ONLY" != "false" ]]; then
  echo "OFFICIAL_ONLY must be true or false" >&2
  exit 1
fi

REPO="${GITHUB_REPOSITORY:-}"
if [[ -z "$REPO" ]]; then
  detect_repo
fi
if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi
if [[ -z "$REPO" ]]; then
  echo "Unable to detect repository name. Set GITHUB_REPOSITORY=owner/repo." >&2
  exit 1
fi

declare -A EXISTING_LABELS

gather_existing_labels() {
  local label
  while IFS= read -r label; do
    [[ -n "$label" ]] && EXISTING_LABELS["$label"]=1
  done < <(gh label list --repo "$REPO" --limit 1000 --json name --jq '.[].name')
}

label_exists() {
  local name="$1"
  [[ -n "${EXISTING_LABELS[$name]+x}" ]]
}

upsert_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  if [[ "$DRY_RUN" == "true" ]]; then
    print_cmd gh label create "$name" --repo "$REPO" --color "$color" --description "$description" --force
    return
  fi

  if label_exists "$name"; then
    gh label edit "$name" --repo "$REPO" --color "$color" --description "$description" >/dev/null
  else
    gh label create "$name" --repo "$REPO" --color "$color" --description "$description" >/dev/null
    EXISTING_LABELS["$name"]=1
  fi
}

declare -A EXISTING_MILESTONES

gather_existing_milestones() {
  local title
  while IFS= read -r title; do
    [[ -n "$title" ]] && EXISTING_MILESTONES["$title"]=1
  done < <(gh api "repos/$REPO/milestones?state=all&per_page=100" --jq '.[].title')
}

milestone_exists() {
  local title="$1"
  [[ -n "${EXISTING_MILESTONES[$title]+x}" ]]
}

create_milestone_if_missing() {
  local title="$1"
  local desc="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    print_cmd gh api -X POST "repos/$REPO/milestones" -f title="$title" -f description="$desc"
    return
  fi

  if milestone_exists "$title"; then
    echo "[skip] milestone exists: $title"
    return
  fi

  gh api -X POST "repos/$REPO/milestones" -f title="$title" -f description="$desc" >/dev/null
  EXISTING_MILESTONES["$title"]=1
  echo "[ok] milestone created: $title"
}

configure_codeowners() {
  local file=".github/CODEOWNERS"
  if [[ ! -f "$file" ]]; then
    echo "[skip] CODEOWNERS not found: $file"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_cmd sed -i "s#@org/architects#$ARCHITECT_TEAM#g" "$file"
    print_cmd sed -i "s#@org/security#$SECURITY_TEAM#g" "$file"
    print_cmd sed -i "s#@org/dba#$DBA_TEAM#g" "$file"
    print_cmd sed -i "s#@org/product#$PRODUCT_TEAM#g" "$file"
    return
  fi

  sed -i "s#@org/architects#$ARCHITECT_TEAM#g" "$file"
  sed -i "s#@org/security#$SECURITY_TEAM#g" "$file"
  sed -i "s#@org/dba#$DBA_TEAM#g" "$file"
  sed -i "s#@org/product#$PRODUCT_TEAM#g" "$file"
  echo "[ok] CODEOWNERS teams applied"
}

print_inputs() {
  cat <<INFO
Repository:      $REPO
DRY_RUN:         $DRY_RUN
PHASE_RANGE:     $PHASE_RANGE
GATE_RULESET:    $GATE_RULESET
REPORT_PATH:     $REPORT_PATH
ARCHITECT_TEAM:  $ARCHITECT_TEAM
SECURITY_TEAM:   $SECURITY_TEAM
DBA_TEAM:        $DBA_TEAM
PRODUCT_TEAM:    $PRODUCT_TEAM
OFFICIAL_ONLY:   $OFFICIAL_ONLY
INIT_MILESTONES: $INIT_MILESTONES
INFO
}

check_paths() {
  local path
  for path in scripts/gates scripts spec CLAUDE.md .github/workflows; do
    if [[ -e "$path" ]]; then
      echo "[ok] path detected: $path"
    else
      echo "[skip] path missing: $path"
    fi
  done
}

setup_labels() {
  echo "==> Setup labels"

  local phase
  for ((phase=0; phase<=END_PHASE; phase++)); do
    upsert_label "phase-$(printf '%02d' "$phase")" "0075ca" "Phase $(printf '%02d' "$phase")"
  done

  upsert_label "type:feature" "0e8a16" "New feature"
  upsert_label "type:bugfix" "d73a4a" "Bug fix"
  upsert_label "type:refactor" "fbca04" "Refactor"
  upsert_label "type:test" "9b59b6" "Testing"
  upsert_label "type:docs" "bfdadc" "Documentation"
  upsert_label "type:gate-fix" "e67e22" "Fix for gate violations"

  upsert_label "priority:P0" "b60205" "Blocker"
  upsert_label "priority:P1" "d93f0b" "High priority"
  upsert_label "priority:P2" "f9d0c4" "Normal priority"

  upsert_label "gate:pass" "0e8a16" "Gate passed"
  upsert_label "gate:fail" "d73a4a" "Gate failed"
  upsert_label "gate:pending" "8a8a8a" "Gate pending"
  upsert_label "gate:skip" "bfdadc" "Gate skipped"

  upsert_label "workflow:brief" "5319e7" "Brief stage"
  upsert_label "workflow:spec" "1d76db" "Spec stage"
  upsert_label "workflow:coding" "0e8a16" "Coding stage"
  upsert_label "workflow:gate" "e67e22" "Gate checking"
  upsert_label "workflow:review" "8a8a8a" "Review stage"
  upsert_label "workflow:done" "0e8a16" "Done stage"

  upsert_label "workstream:baseline" "1d76db" "Baseline workstream"
  upsert_label "workstream:regression" "5319e7" "Regression workstream"
  upsert_label "workstream:coverage" "fbca04" "Coverage workstream"
  upsert_label "workstream:infra" "8a8a8a" "Infra workstream"

  upsert_label "suite:security" "d73a4a" "Security test suite"
  upsert_label "suite:tenant" "e67e22" "Tenant test suite"
  upsert_label "suite:crud" "0e8a16" "CRUD test suite"
  upsert_label "suite:openapi" "1d76db" "OpenAPI test suite"
  upsert_label "suite:perf" "5319e7" "Performance test suite"
  upsert_label "suite:other" "bfdadc" "Other test suite"

  upsert_label "gate-failure" "b60205" "Created from gate failure"
}

setup_milestones() {
  if [[ "$INIT_MILESTONES" != "true" ]]; then
    echo "==> Milestones init disabled (use --init-milestones to enable)"
    return
  fi

  echo "==> Setup milestones"
  local phase title desc
  for ((phase=START_PHASE; phase<=END_PHASE; phase++)); do
    title="Phase $(printf '%02d' "$phase")"
    desc="Phase $(printf '%02d' "$phase") delivery tracking.\nGate ruleset: $GATE_RULESET\nReport path: $REPORT_PATH"
    create_milestone_if_missing "$title" "$desc"
  done
}

main() {
  print_inputs
  check_paths

  if [[ "$DRY_RUN" == "false" ]]; then
    gather_existing_labels
    gather_existing_milestones
  fi

  configure_codeowners
  setup_labels
  setup_milestones

  echo "==> Done"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "Dry-run mode: no GitHub resources were changed."
  fi
}

main "$@"
