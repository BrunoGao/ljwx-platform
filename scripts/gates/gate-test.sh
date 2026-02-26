#!/usr/bin/env bash
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_INPUT="${1:-}"
TMP_DIR="/tmp/ljwx-gate-results"
OUT_JSON="$TMP_DIR/R09.json"
mkdir -p "$TMP_DIR"

normalize_phase() {
  local p="$1"
  if [[ -z "$p" || "$p" == "all" ]]; then
    echo "all"
    return
  fi
  if [[ "$p" =~ ^[0-9]{1,2}$ ]]; then
    printf '%02d' "$((10#$p))"
    return
  fi
  echo "00"
}

PHASE="$(normalize_phase "$PHASE_INPUT")"

phase_done() {
  local ph="$1"
  [[ "$ph" == "all" ]] && return 1
  grep -A40 -E "^## PHASE ${ph#0}$|^## PHASE $((10#$ph))$" PHASE_MANIFEST.txt 2>/dev/null \
    | grep -Eq 'Status:[[:space:]]*PASSED|Gate:[[:space:]]*PASSED|DONE'
}

backend_module() {
  if [[ -d "ljwx-platform-app" ]]; then
    echo "ljwx-platform-app"
    return
  fi
  awk '/<module>/{gsub(/.*<module>|<\/module>.*/,""); print}' pom.xml 2>/dev/null \
    | while read -r m; do
        [[ -f "$m/pom.xml" && -d "$m/src/main/java" ]] && echo "$m"
      done | head -n 1
}

write_json() {
  local status="$1"
  local critical="$2"
  local warnings="$3"
  local message="$4"
  local violations="${5:-[]}"
  jq -n \
    --arg id "R09" \
    --arg name "Tests" \
    --arg status "$status" \
    --arg message "$message" \
    --argjson critical "$critical" \
    --argjson warnings "$warnings" \
    --argjson violations "$violations" \
    '{id:$id,name:$name,status:$status,critical:$critical,warnings:$warnings,message:$message,violations:$violations}' >"$OUT_JSON"
}

if [[ -f "$TMP_DIR/R01.json" ]]; then
  r01_status="$(jq -r '.status // ""' "$TMP_DIR/R01.json" 2>/dev/null || true)"
  if [[ "$r01_status" == "FAIL" ]]; then
    write_json "SKIP" 0 0 "compile gate failed, skip tests"
    exit 0
  fi
fi

MODULE="$(backend_module)"
if [[ -z "$MODULE" ]]; then
  write_json "SKIP" 0 0 "backend module not found"
  exit 0
fi

# Skip R09 for frontend-only phases (targets.backend: false in phase spec)
if [[ "$PHASE" != "all" ]]; then
  PHASE_BRIEF="spec/phase/phase-${PHASE}.md"
  if [[ -f "$PHASE_BRIEF" ]]; then
    backend_target="$(sed -n '/^targets:/,/^[a-z]/p' "$PHASE_BRIEF" | grep 'backend:' | head -1 | sed 's/.*backend:[[:space:]]*//')"
    if [[ "$backend_target" == "false" ]]; then
      write_json "SKIP" 0 0 "frontend-only phase (targets.backend: false) — R09 not applicable"
      exit 0
    fi
  fi
fi

if [[ "$PHASE" == "all" ]]; then
  PKG_DIR_GLOB="$MODULE/src/test/java/com/ljwx/platform/phase*"
else
  PKG_DIR_GLOB="$MODULE/src/test/java/com/ljwx/platform/phase${PHASE}"
fi

if ! ls -d $PKG_DIR_GLOB >/dev/null 2>&1; then
  if phase_done "$PHASE"; then
    write_json "FAIL" 1 0 "phase $PHASE is marked done but no phase test package found"
    exit 1
  fi
  write_json "SKIP" 0 0 "phase test package not found"
  exit 0
fi

rm -f "$MODULE"/target/surefire-reports/*.xml >/dev/null 2>&1 || true

TEST_PATTERN="$(
  find $PKG_DIR_GLOB -type f -name '*.java' 2>/dev/null \
    | sed -E "s|^$MODULE/src/test/java/||; s|/|.|g; s|\\.java$||" \
    | paste -sd, -
)"

if [[ -z "$TEST_PATTERN" ]]; then
  if phase_done "$PHASE"; then
    write_json "FAIL" 1 0 "phase $PHASE is marked done but no test classes found"
    exit 1
  fi
  write_json "SKIP" 0 0 "no phase test classes found"
  exit 0
fi

MVN_OUT="$(mktemp)"
if mvn test -pl "$MODULE" -am -Dtest="$TEST_PATTERN" -Dspring.profiles.active=test -DfailIfNoTests=false -Dsurefire.failIfNoSpecifiedTests=false >"$MVN_OUT" 2>&1; then
  TEST_EXIT=0
else
  TEST_EXIT=$?
fi

REPORT_DIR="$MODULE/target/surefire-reports"
if ! ls "$REPORT_DIR"/TEST-*.xml >/dev/null 2>&1; then
  if phase_done "$PHASE"; then
    write_json "FAIL" 1 0 "phase $PHASE is marked done but no surefire XML produced"
    exit 1
  fi
  write_json "SKIP" 0 0 "no surefire xml reports produced"
  exit 0
fi

total=$(grep -hEo 'tests="[0-9]+"' "$REPORT_DIR"/TEST-*.xml | sed -E 's/[^0-9]//g' | awk '{s+=$1} END{print s+0}')
failures=$(grep -hEo 'failures="[0-9]+"' "$REPORT_DIR"/TEST-*.xml | sed -E 's/[^0-9]//g' | awk '{s+=$1} END{print s+0}')
errors=$(grep -hEo 'errors="[0-9]+"' "$REPORT_DIR"/TEST-*.xml | sed -E 's/[^0-9]//g' | awk '{s+=$1} END{print s+0}')
skipped=$(grep -hEo 'skipped="[0-9]+"' "$REPORT_DIR"/TEST-*.xml | sed -E 's/[^0-9]//g' | awk '{s+=$1} END{print s+0}')

if [[ "$total" -eq 0 ]]; then
  if phase_done "$PHASE"; then
    write_json "FAIL" 1 0 "phase $PHASE is marked done but zero tests executed"
    exit 1
  fi
  write_json "SKIP" 0 0 "zero tests executed"
  exit 0
fi

if [[ "$TEST_EXIT" -ne 0 || $((failures + errors)) -gt 0 ]]; then
  failures_file="$(mktemp)"
  grep -hE '<failure|<error' "$REPORT_DIR"/TEST-*.xml | head -n 20 >"$failures_file" || true

  violations="$(
    awk '
      /<failure|<error/ {
        msg=$0
        gsub(/.*message="/, "", msg)
        gsub(/".*/, "", msg)
        if (msg == "") msg="test failure"
        printf "%s\n", msg
      }
    ' "$failures_file" \
    | jq -R -s 'split("\n") | map(select(length>0)) | map({rule:"R09",severity:"CRITICAL",file:null,line:null,message:.})'
  )"

  write_json "FAIL" "$((failures + errors))" 0 "tests failed: total=$total failures=$failures errors=$errors skipped=$skipped" "$violations"
  exit 1
fi

write_json "PASS" 0 "$skipped" "tests passed: total=$total failures=$failures errors=$errors skipped=$skipped"
exit 0
