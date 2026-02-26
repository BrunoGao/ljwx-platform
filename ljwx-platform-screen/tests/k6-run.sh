#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_DIR="${ROOT_DIR}/tests/results"
RUN_ID="${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"

usage() {
  cat <<USAGE
Usage:
  bash tests/k6-run.sh <e2e-01|e2e-02|perf-baseline> [extra k6 args]

Examples:
  BASE_URL=http://localhost:8080 bash tests/k6-run.sh e2e-01
  BASE_URL=http://localhost:8080 bash tests/k6-run.sh e2e-02 --vus 1 --iterations 1
  BASE_URL=http://localhost:8080 bash tests/k6-run.sh perf-baseline --vus 10 --duration 60s
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

if ! command -v k6 >/dev/null 2>&1; then
  echo "[k6-run] k6 command not found in PATH"
  echo "Install: https://grafana.com/docs/k6/latest/set-up/install-k6/"
  exit 1
fi

NAME="$1"
shift || true

case "${NAME}" in
  e2e-01)
    SCRIPT="${ROOT_DIR}/tests/e2e/e2e-01-auth-rbac.js"
    ;;
  e2e-02)
    SCRIPT="${ROOT_DIR}/tests/e2e/e2e-02-tenant-isolation.js"
    ;;
  perf-baseline)
    SCRIPT="${ROOT_DIR}/tests/perf/baseline.js"
    ;;
  *)
    echo "[k6-run] Unknown test name: ${NAME}"
    usage
    exit 1
    ;;
esac

mkdir -p "${RESULT_DIR}"
SUMMARY_FILE="${RESULT_DIR}/${NAME}_${RUN_ID}_summary.json"
RAW_FILE="${RESULT_DIR}/${NAME}_${RUN_ID}_raw.json"

echo "[k6-run] name=${NAME} run_id=${RUN_ID}"
echo "[k6-run] script=${SCRIPT}"
echo "[k6-run] summary=${SUMMARY_FILE}"
echo "[k6-run] raw=${RAW_FILE}"

k6 run \
  --summary-export "${SUMMARY_FILE}" \
  --out "json=${RAW_FILE}" \
  "${SCRIPT}" "$@"

echo "[k6-run] done"
if command -v jq >/dev/null 2>&1; then
  jq '{metrics: {http_req_duration: .metrics.http_req_duration.values, checks: .metrics.checks.values}}' "${SUMMARY_FILE}" 2>/dev/null || true
fi
