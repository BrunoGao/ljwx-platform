#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

source scripts/ci/policy-lib.sh

PHASE="${CLOSED_LOOP_PHASE:-unknown}"
ATTEMPT="${CLOSED_LOOP_ATTEMPT:-1}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    --attempt) ATTEMPT="$2"; shift 2 ;;
    *) echo "[network-retry-cache] Unknown arg: $1" >&2; exit 2 ;;
  esac
done

ENABLED="$(policy_get_bool 'network.enabled' 'true')"
if [[ "$ENABLED" != "true" ]]; then
  echo "[network-retry-cache] disabled by policy"
  exit 0
fi

MAX_RETRIES="$(policy_get 'network.max_retries' '3')"
BACKOFF_SEC="$(policy_get 'network.backoff_sec' '6')"
CACHE_ENABLED="$(policy_get_bool 'network.cache.enabled' 'true')"
PNPM_FETCH="$(policy_get_bool 'network.cache.pnpm_fetch' 'true')"
MAVEN_GO_OFFLINE="$(policy_get_bool 'network.cache.maven_go_offline' 'true')"
PNPM_STORE_DIR="$(policy_get 'network.cache.pnpm_store_dir' '.cache/pnpm-store')"
MAVEN_LOCAL_REPO="$(policy_get 'network.cache.maven_local_repo' '.cache/m2/repository')"
MIRROR_ENABLED="$(policy_get_bool 'network.mirror.enabled' 'false')"
PNPM_REGISTRY="$(policy_get 'network.mirror.pnpm_registry' 'https://registry.npmjs.org')"
CB_THRESHOLD="$(policy_get 'network.circuit_breaker.failure_threshold' '3')"
CB_COOLDOWN="$(policy_get 'network.circuit_breaker.cooldown_sec' '1800')"

[[ "$MAX_RETRIES" =~ ^[0-9]+$ ]] || MAX_RETRIES=3
[[ "$BACKOFF_SEC" =~ ^[0-9]+$ ]] || BACKOFF_SEC=6
[[ "$CB_THRESHOLD" =~ ^[0-9]+$ ]] || CB_THRESHOLD=3
[[ "$CB_COOLDOWN" =~ ^[0-9]+$ ]] || CB_COOLDOWN=1800

cb_allow_or_exit "network"

ART_DIR="artifacts/closed-loop/network/phase-${PHASE}"
mkdir -p "$ART_DIR"
LOG_FILE="${ART_DIR}/attempt-${ATTEMPT}.log"

run_with_retry() {
  local label="$1"
  local cmd="$2"
  local i rc
  rc=1
  for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "[network-retry-cache] ${label} try ${i}/${MAX_RETRIES}" | tee -a "$LOG_FILE"
    set +e
    bash -lc "$cmd" 2>&1 | tee -a "$LOG_FILE"
    rc=${PIPESTATUS[0]}
    set -e
    if [[ "$rc" -eq 0 ]]; then
      return 0
    fi
    if (( i < MAX_RETRIES )); then
      sleep "$BACKOFF_SEC"
    fi
  done
  return "$rc"
}

echo "[network-retry-cache] phase=${PHASE} closed-loop-attempt=${ATTEMPT}" | tee -a "$LOG_FILE"
echo "[network-retry-cache] retries=${MAX_RETRIES} backoff=${BACKOFF_SEC}s cache=${CACHE_ENABLED}" | tee -a "$LOG_FILE"

if [[ "$MIRROR_ENABLED" == "true" ]]; then
  export NPM_CONFIG_REGISTRY="$PNPM_REGISTRY"
  echo "[network-retry-cache] mirror enabled: NPM_CONFIG_REGISTRY=${NPM_CONFIG_REGISTRY}" | tee -a "$LOG_FILE"
fi

FAILURES=0
ACTIONS=0

if ! mkdir -p "$PNPM_STORE_DIR" "$MAVEN_LOCAL_REPO" 2>>"$LOG_FILE"; then
  echo "[network-retry-cache] failed to prepare cache directories" | tee -a "$LOG_FILE"
  FAILURES=$((FAILURES + 1))
fi

if [[ "$CACHE_ENABLED" == "true" && "$PNPM_FETCH" == "true" && -f "pnpm-lock.yaml" ]]; then
  if command -v pnpm >/dev/null 2>&1; then
    ACTIONS=$((ACTIONS + 1))
    run_with_retry \
      "pnpm-fetch" \
      "pnpm fetch --prefer-offline --store-dir \"${PNPM_STORE_DIR}\"" \
      || FAILURES=$((FAILURES + 1))
  else
    echo "[network-retry-cache] pnpm not found, skip pnpm cache warmup" | tee -a "$LOG_FILE"
  fi
fi

if [[ "$CACHE_ENABLED" == "true" && "$MAVEN_GO_OFFLINE" == "true" && -f "pom.xml" ]]; then
  if command -v mvn >/dev/null 2>&1; then
    ACTIONS=$((ACTIONS + 1))
    run_with_retry \
      "maven-go-offline" \
      "mvn -B -ntp -q -f pom.xml -DskipTests -Dmaven.repo.local=\"${MAVEN_LOCAL_REPO}\" -Dmaven.wagon.http.retryHandler.count=${MAX_RETRIES} dependency:go-offline" \
      || FAILURES=$((FAILURES + 1))
  else
    echo "[network-retry-cache] mvn not found, skip maven cache warmup" | tee -a "$LOG_FILE"
  fi
fi

if [[ "$ACTIONS" -eq 0 ]]; then
  echo "[network-retry-cache] no cache warmup action executed" | tee -a "$LOG_FILE"
fi

if [[ "$FAILURES" -gt 0 ]]; then
  echo "[network-retry-cache] failed actions=${FAILURES}" | tee -a "$LOG_FILE"
  cb_record_failure "network" "$CB_THRESHOLD" "$CB_COOLDOWN"
  exit 1
fi

cb_record_success "network"
echo "[network-retry-cache] mitigation success" | tee -a "$LOG_FILE"
exit 0
