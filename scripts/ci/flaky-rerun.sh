#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

source scripts/ci/policy-lib.sh

TEST_CMD=""
PHASE="${CLOSED_LOOP_PHASE:-unknown}"
ATTEMPT="${CLOSED_LOOP_ATTEMPT:-1}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cmd) TEST_CMD="$2"; shift 2 ;;
    --phase) PHASE="$2"; shift 2 ;;
    --attempt) ATTEMPT="$2"; shift 2 ;;
    *) echo "[flaky-rerun] Unknown arg: $1" >&2; exit 2 ;;
  esac
done

ENABLED="$(policy_get_bool 'flaky.enabled' 'true')"
if [[ "$ENABLED" != "true" ]]; then
  echo "[flaky-rerun] disabled by policy"
  exit 0
fi

MAX_RERUNS="$(policy_get 'flaky.max_reruns' '3')"
BACKOFF_SEC="$(policy_get 'flaky.backoff_sec' '5')"
CB_THRESHOLD="$(policy_get 'flaky.circuit_breaker.failure_threshold' '2')"
CB_COOLDOWN="$(policy_get 'flaky.circuit_breaker.cooldown_sec' '1200')"
[[ "$MAX_RERUNS" =~ ^[0-9]+$ ]] || MAX_RERUNS=3
[[ "$BACKOFF_SEC" =~ ^[0-9]+$ ]] || BACKOFF_SEC=5
[[ "$CB_THRESHOLD" =~ ^[0-9]+$ ]] || CB_THRESHOLD=2
[[ "$CB_COOLDOWN" =~ ^[0-9]+$ ]] || CB_COOLDOWN=1200

if [[ -z "$TEST_CMD" ]]; then
  TEST_CMD="$(policy_get 'flaky.default_test_cmd' 'mvn -B -ntp -q -f pom.xml -DskipITs test')"
fi

cb_allow_or_exit "flaky-test"

ART_DIR="artifacts/closed-loop/flaky/phase-${PHASE}"
mkdir -p "$ART_DIR"
LOG_FILE="${ART_DIR}/attempt-${ATTEMPT}.log"

TOTAL_ATTEMPTS=$((MAX_RERUNS + 1))
PASS_ON_ATTEMPT=0
LAST_EXIT=1

echo "[flaky-rerun] phase=${PHASE} closed-loop-attempt=${ATTEMPT} test-reruns=${MAX_RERUNS}"
echo "[flaky-rerun] cmd: ${TEST_CMD}"

for ((i=1; i<=TOTAL_ATTEMPTS; i++)); do
  echo "[flaky-rerun] run ${i}/${TOTAL_ATTEMPTS}" | tee -a "$LOG_FILE"
  set +e
  bash -lc "$TEST_CMD" 2>&1 | tee -a "$LOG_FILE"
  rc=${PIPESTATUS[0]}
  set -e
  LAST_EXIT="$rc"
  if [[ "$rc" -eq 0 ]]; then
    PASS_ON_ATTEMPT="$i"
    break
  fi
  if (( i < TOTAL_ATTEMPTS )); then
    sleep "$BACKOFF_SEC"
  fi
done

if [[ "$PASS_ON_ATTEMPT" -gt 0 ]]; then
  if [[ "$PASS_ON_ATTEMPT" -gt 1 ]]; then
    echo "[flaky-rerun] flaky recovered on rerun #$((PASS_ON_ATTEMPT - 1))" | tee -a "$LOG_FILE"
  else
    echo "[flaky-rerun] test passed on first run" | tee -a "$LOG_FILE"
  fi
  cb_record_success "flaky-test"
  exit 0
fi

echo "[flaky-rerun] failed after ${TOTAL_ATTEMPTS} attempts (last exit=${LAST_EXIT})" | tee -a "$LOG_FILE"
cb_record_failure "flaky-test" "$CB_THRESHOLD" "$CB_COOLDOWN"
exit "$LAST_EXIT"
