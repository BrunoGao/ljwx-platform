#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TMP_DIR="${TMP_DIR:-/tmp/ljwx-gate-results/observability}"
REPORT_DIR="${REPORT_DIR:-/tmp/ljwx-gate-results}"
REPORT_FILE="${REPORT_FILE:-${REPORT_DIR}/observability-e2e.json}"
ASSERTIONS_FILE="${TMP_DIR}/assertions.ndjson"

APP_NAMESPACE="${APP_NAMESPACE:-ljwx-platform}"
APP_SERVICE="${APP_SERVICE:-ljwx-platform}"
APP_SERVICE_PORT="${APP_SERVICE_PORT:-80}"
APP_LOCAL_PORT="${APP_LOCAL_PORT:-18080}"

MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
PROM_SERVICE="${PROM_SERVICE:-prometheus-kube-prometheus-prometheus}"
PROM_SERVICE_PORT="${PROM_SERVICE_PORT:-9090}"
PROM_LOCAL_PORT="${PROM_LOCAL_PORT:-19090}"

LOKI_NAMESPACE="${LOKI_NAMESPACE:-logging}"
LOKI_SERVICE="${LOKI_SERVICE:-loki}"
LOKI_SERVICE_PORT="${LOKI_SERVICE_PORT:-3100}"
LOKI_LOCAL_PORT="${LOKI_LOCAL_PORT:-13100}"
LOKI_ORG_ID="${LOKI_ORG_ID:-1}"

TRACING_NAMESPACE="${TRACING_NAMESPACE:-tracing}"
TEMPO_SERVICE="${TEMPO_SERVICE:-tempo}"
TEMPO_SERVICE_PORT="${TEMPO_SERVICE_PORT:-3200}"
TEMPO_LOCAL_PORT="${TEMPO_LOCAL_PORT:-13200}"

SERVICE_NAME="${SERVICE_NAME:-ljwx-platform}"
PROM_WINDOW="${PROM_WINDOW:-5m}"
LOKI_WINDOW="${LOKI_WINDOW:-5m}"

RUN_R10="${RUN_R10:-1}"
RUN_R11="${RUN_R11:-1}"
K6_VUS_R10="${K6_VUS_R10:-1}"
K6_ITERATIONS_R10="${K6_ITERATIONS_R10:-1}"
K6_VUS_R11="${K6_VUS_R11:-3}"
K6_DURATION_R11="${K6_DURATION_R11:-20s}"
STRICT_TEMPO_SEARCH="${STRICT_TEMPO_SEARCH:-1}"
AUTO_REPAIR_R10_FIXTURES="${AUTO_REPAIR_R10_FIXTURES:-1}"
R10_FIXTURE_REQUIRED="${R10_FIXTURE_REQUIRED:-0}"

export TENANT_A_USER="${TENANT_A_USER:-admin}"
export TENANT_A_PASS="${TENANT_A_PASS:-${LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD:-}}"
export TENANT_B_USER="${TENANT_B_USER:-tenantB_admin}"
export TENANT_B_PASS="${TENANT_B_PASS:-}"
export TENANT_B_PASS_HASH="${TENANT_B_PASS_HASH:-}"

R10_JSON="/tmp/ljwx-gate-results/R10.json"
R11_JSON="/tmp/ljwx-gate-results/R11.json"

PROM_REQUEST_INCREASE_5M="0"
PROM_P95_5M="0"
LOKI_LOG_COUNT_5M="0"
LOKI_TRACEID_COUNT_5M="0"
TEMPO_SPANS_RECEIVED_TOTAL="0"
TEMPO_SEARCH_COUNT="0"
TEMPO_SERVICE_FOUND="0"
TEMPO_READY="false"

R10_EXEC_RC=-1
R11_EXEC_RC=-1
R10_STATUS="SKIP"
R11_STATUS="SKIP"
R10_MESSAGE=""
R11_MESSAGE=""

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
PF_PIDS=()

log_info() {
  echo "[信息] $*"
}

log_warn() {
  echo "[警告] $*" >&2
}

log_error() {
  echo "[错误] $*" >&2
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    log_error "缺少依赖命令: ${cmd}"
    exit 1
  fi
}

to_json_number() {
  local value="${1:-0}"
  jq -nc --arg v "${value}" '$v | tonumber? // 0'
}

is_gt_zero() {
  local value="${1:-0}"
  awk -v v="${value}" 'BEGIN { exit !(v + 0 > 0) }'
}

json_file_value() {
  local file="$1"
  local filter="$2"
  local fallback="${3:-}"
  if [[ ! -s "${file}" ]]; then
    echo "${fallback}"
    return
  fi

  local value
  value="$(jq -r "${filter}" "${file}" 2>/dev/null || true)"
  if [[ -z "${value}" || "${value}" == "null" ]]; then
    echo "${fallback}"
    return
  fi

  echo "${value}"
}

record_assertion() {
  local id="$1"
  local name="$2"
  local passed="$3"
  local expected="$4"
  local actual="$5"
  local detail="$6"
  local severity="${7:-error}"

  if [[ "${passed}" == "true" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
  elif [[ "${severity}" == "warning" ]]; then
    WARN_COUNT=$((WARN_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  jq -nc \
    --arg id "${id}" \
    --arg name "${name}" \
    --argjson passed "${passed}" \
    --arg expected "${expected}" \
    --arg actual "${actual}" \
    --arg detail "${detail}" \
    --arg severity "${severity}" \
    '{id:$id,name:$name,passed:$passed,expected:$expected,actual:$actual,detail:$detail,severity:$severity}' >> "${ASSERTIONS_FILE}"
}

record_threshold_assertion() {
  local id="$1"
  local name="$2"
  local value="$3"
  local detail="$4"

  if is_gt_zero "${value}"; then
    record_assertion "${id}" "${name}" "true" "> 0" "${value}" "${detail}"
  else
    record_assertion "${id}" "${name}" "false" "> 0" "${value}" "${detail}"
  fi
}

record_threshold_warning_assertion() {
  local id="$1"
  local name="$2"
  local value="$3"
  local detail="$4"

  if is_gt_zero "${value}"; then
    record_assertion "${id}" "${name}" "true" "> 0" "${value}" "${detail}" "warning"
  else
    record_assertion "${id}" "${name}" "false" "> 0" "${value}" "${detail}" "warning"
  fi
}

cleanup() {
  local pid
  for pid in "${PF_PIDS[@]:-}"; do
    kill "${pid}" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

start_port_forward() {
  local namespace="$1"
  local service="$2"
  local local_port="$3"
  local remote_port="$4"
  local label="$5"
  local log_file="${TMP_DIR}/pf-${label}.log"

  : > "${log_file}"
  kubectl port-forward -n "${namespace}" "svc/${service}" "${local_port}:${remote_port}" >"${log_file}" 2>&1 &
  local pid=$!
  PF_PIDS+=("${pid}")

  local i
  for i in $(seq 1 25); do
    if ! kill -0 "${pid}" >/dev/null 2>&1; then
      log_error "端口转发失败: ${namespace}/svc/${service} ${local_port}:${remote_port}"
      sed -n '1,120p' "${log_file}" >&2 || true
      return 1
    fi
    if grep -q "Forwarding from" "${log_file}"; then
      return 0
    fi
    sleep 0.2
  done

  log_error "端口转发超时: ${namespace}/svc/${service} ${local_port}:${remote_port}"
  sed -n '1,120p' "${log_file}" >&2 || true
  return 1
}

prom_query_value() {
  local query="$1"
  local body_file="${TMP_DIR}/prom-query.json"
  local http_code

  set +e
  http_code="$(curl -sS -o "${body_file}" -w '%{http_code}' -G "http://127.0.0.1:${PROM_LOCAL_PORT}/api/v1/query" --data-urlencode "query=${query}")"
  local rc=$?
  set -e

  if [[ "${rc}" -ne 0 || "${http_code}" != "200" ]]; then
    echo "0"
    return
  fi

  jq -r '.data.result[0].value[1] // "0"' "${body_file}" 2>/dev/null || echo "0"
}

loki_query_value() {
  local query="$1"
  local body_file="${TMP_DIR}/loki-query.json"
  local http_code

  set +e
  http_code="$(curl -sS -o "${body_file}" -w '%{http_code}' -H "X-Scope-OrgID: ${LOKI_ORG_ID}" -G "http://127.0.0.1:${LOKI_LOCAL_PORT}/loki/api/v1/query" --data-urlencode "query=${query}")"
  local rc=$?
  set -e

  if [[ "${rc}" -ne 0 || "${http_code}" != "200" ]]; then
    echo "0"
    return
  fi

  jq -r '.data.result[0].value[1] // "0"' "${body_file}" 2>/dev/null || echo "0"
}

tempo_search_count() {
  local body_file="${TMP_DIR}/tempo-search.json"
  local http_code

  set +e
  http_code="$(curl -sS -o "${body_file}" -w '%{http_code}' "http://127.0.0.1:${TEMPO_LOCAL_PORT}/api/search?limit=20")"
  local rc=$?
  set -e

  if [[ "${rc}" -ne 0 || "${http_code}" != "200" ]]; then
    echo "0"
    return
  fi

  jq -r '.traces | length // 0' "${body_file}" 2>/dev/null || echo "0"
}

tempo_service_found() {
  local body_file="${TMP_DIR}/tempo-tag-values.json"
  local http_code

  set +e
  http_code="$(curl -sS -o "${body_file}" -w '%{http_code}' "http://127.0.0.1:${TEMPO_LOCAL_PORT}/api/search/tag/service.name/values")"
  local rc=$?
  set -e

  if [[ "${rc}" -ne 0 || "${http_code}" != "200" ]]; then
    echo "0"
    return
  fi

  jq -r --arg svc "${SERVICE_NAME}" '[.tagValues[]? | select(. == $svc)] | length' "${body_file}" 2>/dev/null || echo "0"
}

tempo_spans_received_total() {
  local body_file="${TMP_DIR}/tempo-metrics.txt"
  local http_code

  set +e
  http_code="$(curl -sS -o "${body_file}" -w '%{http_code}' "http://127.0.0.1:${TEMPO_LOCAL_PORT}/metrics")"
  local rc=$?
  set -e

  if [[ "${rc}" -ne 0 || "${http_code}" != "200" ]]; then
    echo "0"
    return
  fi

  awk '/^tempo_distributor_spans_received_total/ {sum += $2} END {print sum + 0}' "${body_file}"
}

tempo_ready_status() {
  local body_file="${TMP_DIR}/tempo-ready.txt"
  local http_code

  set +e
  http_code="$(curl -sS -o "${body_file}" -w '%{http_code}' "http://127.0.0.1:${TEMPO_LOCAL_PORT}/ready")"
  local rc=$?
  set -e

  if [[ "${rc}" -ne 0 || "${http_code}" != "200" ]]; then
    echo "false"
    return
  fi

  local body
  body="$(cat "${body_file}" 2>/dev/null || true)"
  if [[ "${body}" == "ready" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

prepare_r10_fixtures() {
  if [[ "${RUN_R10}" != "1" ]]; then
    return
  fi

  if [[ "${AUTO_REPAIR_R10_FIXTURES}" != "1" ]]; then
    log_info "跳过 R10 夹具修复（AUTO_REPAIR_R10_FIXTURES=${AUTO_REPAIR_R10_FIXTURES}）"
    return
  fi

  local seed_script="${PROJECT_ROOT}/scripts/e2e/seed-fixtures-k3s.sh"
  if [[ ! -x "${seed_script}" ]]; then
    log_warn "R10 夹具修复脚本不存在或不可执行: ${seed_script}"
    if [[ "${R10_FIXTURE_REQUIRED}" == "1" ]]; then
      log_error "R10_FIXTURE_REQUIRED=1 且夹具修复脚本不可用。"
      exit 1
    fi
    return
  fi

  log_info "执行 R10 夹具修复..."
  set +e
  APP_NAMESPACE="${APP_NAMESPACE}" \
  TENANT_B_USER="${TENANT_B_USER}" \
  TENANT_B_PASS="${TENANT_B_PASS}" \
  TENANT_B_PASS_HASH="${TENANT_B_PASS_HASH}" \
  bash "${seed_script}" >"${TMP_DIR}/seed-fixtures.log" 2>&1
  local rc=$?
  set -e

  if [[ "${rc}" -eq 0 ]]; then
    log_info "R10 夹具修复完成。"
    return
  fi

  log_warn "R10 夹具修复失败(rc=${rc})，继续执行 gate。"
  if [[ -f "${TMP_DIR}/seed-fixtures.log" ]]; then
    tail -n 40 "${TMP_DIR}/seed-fixtures.log" >&2 || true
  fi

  if [[ "${R10_FIXTURE_REQUIRED}" == "1" ]]; then
    log_error "R10_FIXTURE_REQUIRED=1 且夹具修复失败。"
    exit 1
  fi
}

dump_r10_diagnostics() {
  log_warn "R10 失败诊断：TENANT_A_USER=${TENANT_A_USER}, TENANT_B_USER=${TENANT_B_USER}"

  if [[ -s "${R10_JSON}" ]]; then
    local r10_brief
    r10_brief="$(jq -c '{status,message,checks,passed,failed,p95_ms}' "${R10_JSON}" 2>/dev/null || true)"
    if [[ -n "${r10_brief}" ]]; then
      log_warn "R10 JSON 摘要: ${r10_brief}"
    fi
  fi

  if [[ -f "${TMP_DIR}/gate-e2e.log" ]]; then
    log_warn "gate-e2e.log 关键行："
    grep -E 'Login failed|expected=200 actual=40[1-3]|actual=500|GoError|script exception|tenantB|用户名或密码错误|账号已锁定|423001|401001' "${TMP_DIR}/gate-e2e.log" \
      | head -n 30 >&2 || true
  fi

  local k6_log
  for k6_log in /tmp/ljwx-gate-results/k6/e2e_*.log.*; do
    if [[ -f "${k6_log}" ]]; then
      log_warn "k6 日志 $(basename "${k6_log}") 关键行："
      grep -E 'Login failed|expected=200 actual=40[1-3]|actual=500|GoError|script exception|tenantB|用户名或密码错误|账号已锁定|423001|401001' "${k6_log}" \
        | head -n 30 >&2 || true
    fi
  done
}

dump_r11_diagnostics() {
  log_warn "R11 失败诊断：R11_EXEC_RC=${R11_EXEC_RC}, R11_STATUS=${R11_STATUS}"

  if [[ -s "${R11_JSON}" ]]; then
    local r11_brief
    r11_brief="$(jq -c '{status,message,checks,passed,failed,p95_ms,avg_ms}' "${R11_JSON}" 2>/dev/null || true)"
    if [[ -n "${r11_brief}" ]]; then
      log_warn "R11 JSON 摘要: ${r11_brief}"
    fi
  fi

  if [[ -f "${TMP_DIR}/gate-perf.log" ]]; then
    log_warn "gate-perf.log 关键行："
    grep -E 'Login failed|GoError|script exception|ERRO|actual=40[0-9]|actual=500|threshold|k6 is not available|docker fallback' "${TMP_DIR}/gate-perf.log" \
      | head -n 40 >&2 || true
  fi

  local perf_log
  for perf_log in /tmp/ljwx-gate-results/k6/perf*.log.*; do
    if [[ -f "${perf_log}" ]]; then
      log_warn "k6 性能日志 $(basename "${perf_log}") 关键行："
      grep -E 'Login failed|GoError|script exception|ERRO|actual=40[0-9]|actual=500|threshold' "${perf_log}" \
        | head -n 30 >&2 || true
    fi
  done
}

run_r10() {
  if [[ "${RUN_R10}" != "1" ]]; then
    log_info "跳过 R10（RUN_R10=${RUN_R10}）"
    return
  fi

  log_info "执行 R10 E2E gate..."
  log_info "R10 账号参数：TENANT_A_USER=${TENANT_A_USER}, TENANT_B_USER=${TENANT_B_USER}"
  set +e
  BASE_URL="http://127.0.0.1:${APP_LOCAL_PORT}" \
  K6_VUS="${K6_VUS_R10}" \
  K6_ITERATIONS="${K6_ITERATIONS_R10}" \
  bash "${PROJECT_ROOT}/scripts/gates/gate-e2e.sh" >"${TMP_DIR}/gate-e2e.log" 2>&1
  R10_EXEC_RC=$?
  set -e

  R10_STATUS="$(json_file_value "${R10_JSON}" '.status' "UNKNOWN")"
  R10_MESSAGE="$(json_file_value "${R10_JSON}" '.message' "")"
  if [[ "${R10_EXEC_RC}" -ne 0 && ( -z "${R10_STATUS}" || "${R10_STATUS}" == "UNKNOWN" || "${R10_STATUS}" == "null" ) ]]; then
    R10_STATUS="FAIL"
    if [[ -z "${R10_MESSAGE}" ]]; then
      R10_MESSAGE="R10 report missing (gate-e2e rc=${R10_EXEC_RC})"
    fi
  fi

  if [[ "${R10_EXEC_RC}" -eq 0 && "${R10_STATUS}" == "PASS" ]]; then
    record_assertion "gate_r10" "R10 E2E Gate" "true" "PASS" "${R10_STATUS}" "${R10_MESSAGE}"
  else
    record_assertion "gate_r10" "R10 E2E Gate" "false" "PASS" "${R10_STATUS}" "rc=${R10_EXEC_RC}; ${R10_MESSAGE}"
    dump_r10_diagnostics
  fi
}

run_r11() {
  if [[ "${RUN_R11}" != "1" ]]; then
    log_info "跳过 R11（RUN_R11=${RUN_R11}）"
    return
  fi

  log_info "执行 R11 Perf gate..."
  set +e
  BASE_URL="http://127.0.0.1:${APP_LOCAL_PORT}" \
  K6_VUS="${K6_VUS_R11}" \
  K6_DURATION="${K6_DURATION_R11}" \
  bash "${PROJECT_ROOT}/scripts/gates/gate-perf.sh" >"${TMP_DIR}/gate-perf.log" 2>&1
  R11_EXEC_RC=$?
  set -e

  R11_STATUS="$(json_file_value "${R11_JSON}" '.status' "UNKNOWN")"
  R11_MESSAGE="$(json_file_value "${R11_JSON}" '.message' "")"
  if [[ "${R11_EXEC_RC}" -ne 0 && ( -z "${R11_STATUS}" || "${R11_STATUS}" == "UNKNOWN" || "${R11_STATUS}" == "null" ) ]]; then
    R11_STATUS="FAIL"
    if [[ -z "${R11_MESSAGE}" ]]; then
      R11_MESSAGE="R11 report missing (gate-perf rc=${R11_EXEC_RC})"
    fi
  fi

  if [[ "${R11_EXEC_RC}" -eq 0 && "${R11_STATUS}" == "PASS" ]]; then
    record_assertion "gate_r11" "R11 Perf Gate" "true" "PASS" "${R11_STATUS}" "${R11_MESSAGE}"
  else
    record_assertion "gate_r11" "R11 Perf Gate" "false" "PASS" "${R11_STATUS}" "rc=${R11_EXEC_RC}; ${R11_MESSAGE}"
    dump_r11_diagnostics
  fi
}

run_prom_assertions() {
  log_info "执行 Prometheus 断言..."
  PROM_REQUEST_INCREASE_5M="$(prom_query_value "sum(increase(http_server_requests_seconds_count{application=\"${SERVICE_NAME}\"}[${PROM_WINDOW}]))")"
  PROM_P95_5M="$(prom_query_value "(histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket{application=\"${SERVICE_NAME}\"}[${PROM_WINDOW}])) by (le)) or histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{application=\"${SERVICE_NAME}\"}[${PROM_WINDOW}])) by (le)))")"

  record_threshold_assertion "prom_request_increase" "Prometheus 请求增量" "${PROM_REQUEST_INCREASE_5M}" "query=sum(increase(http_server_requests_seconds_count{application=\"${SERVICE_NAME}\"}[${PROM_WINDOW}]))"
  record_threshold_assertion "prom_p95" "Prometheus P95 延迟" "${PROM_P95_5M}" "query=histogram_quantile p95"
}

run_loki_assertions() {
  log_info "执行 Loki 断言..."
  LOKI_LOG_COUNT_5M="$(loki_query_value "sum(count_over_time({app=\"${SERVICE_NAME}\"}[${LOKI_WINDOW}]))")"
  LOKI_TRACEID_COUNT_5M="$(loki_query_value "sum(count_over_time({app=\"${SERVICE_NAME}\"} | json | traceId != \"\" [${LOKI_WINDOW}]))")"

  record_threshold_assertion "loki_log_count" "Loki 日志条数" "${LOKI_LOG_COUNT_5M}" "query=sum(count_over_time({app=\"${SERVICE_NAME}\"}[${LOKI_WINDOW}]))"
  record_threshold_assertion "loki_traceid_count" "Loki TraceId 日志条数" "${LOKI_TRACEID_COUNT_5M}" "query=sum(count_over_time({app=\"${SERVICE_NAME}\"} | json | traceId != \"\" [${LOKI_WINDOW}]))"
}

run_tempo_assertions() {
  log_info "执行 Tempo 断言..."
  TEMPO_READY="$(tempo_ready_status)"
  TEMPO_SPANS_RECEIVED_TOTAL="$(tempo_spans_received_total)"
  TEMPO_SEARCH_COUNT="$(tempo_search_count)"
  TEMPO_SERVICE_FOUND="$(tempo_service_found)"

  if [[ "${TEMPO_READY}" == "true" ]]; then
    record_assertion "tempo_ready" "Tempo Ready" "true" "true" "${TEMPO_READY}" "/ready"
  else
    record_assertion "tempo_ready" "Tempo Ready" "false" "true" "${TEMPO_READY}" "/ready"
  fi

  record_threshold_assertion "tempo_spans_received_total" "Tempo spans_received_total" "${TEMPO_SPANS_RECEIVED_TOTAL}" "metrics=tempo_distributor_spans_received_total"
  if [[ "${STRICT_TEMPO_SEARCH}" == "1" ]]; then
    record_threshold_assertion "tempo_search_count" "Tempo Trace 搜索结果数" "${TEMPO_SEARCH_COUNT}" "api=/api/search?limit=20"
    record_threshold_assertion "tempo_service_found" "Tempo service.name 包含目标服务" "${TEMPO_SERVICE_FOUND}" "api=/api/search/tag/service.name/values, service=${SERVICE_NAME}"
  else
    record_threshold_warning_assertion "tempo_search_count" "Tempo Trace 搜索结果数" "${TEMPO_SEARCH_COUNT}" "api=/api/search?limit=20; STRICT_TEMPO_SEARCH=0"
    record_threshold_warning_assertion "tempo_service_found" "Tempo service.name 包含目标服务" "${TEMPO_SERVICE_FOUND}" "api=/api/search/tag/service.name/values, service=${SERVICE_NAME}; STRICT_TEMPO_SEARCH=0"
  fi
}

write_report() {
  local status="PASS"
  if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    status="FAIL"
  fi

  local assertions_json
  if [[ -s "${ASSERTIONS_FILE}" ]]; then
    assertions_json="$(jq -s '.' "${ASSERTIONS_FILE}")"
  else
    assertions_json='[]'
  fi

  local pass_json fail_json warn_json
  pass_json="$(to_json_number "${PASS_COUNT}")"
  fail_json="$(to_json_number "${FAIL_COUNT}")"
  warn_json="$(to_json_number "${WARN_COUNT}")"

  local prom_req_json prom_p95_json loki_count_json loki_trace_json tempo_spans_json tempo_search_json tempo_service_json
  prom_req_json="$(to_json_number "${PROM_REQUEST_INCREASE_5M}")"
  prom_p95_json="$(to_json_number "${PROM_P95_5M}")"
  loki_count_json="$(to_json_number "${LOKI_LOG_COUNT_5M}")"
  loki_trace_json="$(to_json_number "${LOKI_TRACEID_COUNT_5M}")"
  tempo_spans_json="$(to_json_number "${TEMPO_SPANS_RECEIVED_TOTAL}")"
  tempo_search_json="$(to_json_number "${TEMPO_SEARCH_COUNT}")"
  tempo_service_json="$(to_json_number "${TEMPO_SERVICE_FOUND}")"

  mkdir -p "${REPORT_DIR}"
  jq -n \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "${status}" \
    --arg service_name "${SERVICE_NAME}" \
    --arg app_namespace "${APP_NAMESPACE}" \
    --arg app_service "${APP_SERVICE}" \
    --arg strict_tempo_search "${STRICT_TEMPO_SEARCH}" \
    --arg prom_window "${PROM_WINDOW}" \
    --arg loki_window "${LOKI_WINDOW}" \
    --arg r10_status "${R10_STATUS}" \
    --arg r10_message "${R10_MESSAGE}" \
    --argjson r10_exec_rc "$(to_json_number "${R10_EXEC_RC}")" \
    --arg r11_status "${R11_STATUS}" \
    --arg r11_message "${R11_MESSAGE}" \
    --argjson r11_exec_rc "$(to_json_number "${R11_EXEC_RC}")" \
    --argjson prom_request_increase_5m "${prom_req_json}" \
    --argjson prom_p95_5m "${prom_p95_json}" \
    --argjson loki_log_count_5m "${loki_count_json}" \
    --argjson loki_traceid_count_5m "${loki_trace_json}" \
    --arg tempo_ready "${TEMPO_READY}" \
    --argjson tempo_spans_received_total "${tempo_spans_json}" \
    --argjson tempo_search_count "${tempo_search_json}" \
    --argjson tempo_service_found "${tempo_service_json}" \
    --argjson pass_count "${pass_json}" \
    --argjson fail_count "${fail_json}" \
    --argjson warn_count "${warn_json}" \
    --argjson assertions "${assertions_json}" \
    '{
      timestamp: $timestamp,
      status: $status,
      target: {
        service_name: $service_name,
        app_namespace: $app_namespace,
        app_service: $app_service,
        strict_tempo_search: $strict_tempo_search
      },
      gates: {
        r10: {exec_rc: $r10_exec_rc, status: $r10_status, message: $r10_message},
        r11: {exec_rc: $r11_exec_rc, status: $r11_status, message: $r11_message}
      },
      metrics: {
        prom_window: $prom_window,
        loki_window: $loki_window,
        prom_request_increase_5m: $prom_request_increase_5m,
        prom_p95_5m: $prom_p95_5m,
        loki_log_count_5m: $loki_log_count_5m,
        loki_traceid_count_5m: $loki_traceid_count_5m,
        tempo_ready: $tempo_ready,
        tempo_spans_received_total: $tempo_spans_received_total,
        tempo_search_count: $tempo_search_count,
        tempo_service_found: $tempo_service_found
      },
      summary: {
        pass_count: $pass_count,
        fail_count: $fail_count,
        warn_count: $warn_count
      },
      assertions: $assertions
    }' > "${REPORT_FILE}"

  log_info "验收报告已生成: ${REPORT_FILE}"
  jq '.summary + {status: .status}' "${REPORT_FILE}"

  if [[ "${status}" != "PASS" ]]; then
    log_error "端到端可观测验收失败，请查看 assertions 与 gate 日志。"
    exit 1
  fi
}

main() {
  require_command kubectl
  require_command jq
  require_command curl
  require_command awk

  mkdir -p "${TMP_DIR}" "${REPORT_DIR}"
  : > "${ASSERTIONS_FILE}"

  if [[ -z "${SERVICE_NAME}" ]]; then
    log_error "SERVICE_NAME 不能为空。"
    exit 1
  fi

  log_info "启动端口转发..."
  start_port_forward "${APP_NAMESPACE}" "${APP_SERVICE}" "${APP_LOCAL_PORT}" "${APP_SERVICE_PORT}" "app"
  start_port_forward "${MONITORING_NAMESPACE}" "${PROM_SERVICE}" "${PROM_LOCAL_PORT}" "${PROM_SERVICE_PORT}" "prom"
  start_port_forward "${LOKI_NAMESPACE}" "${LOKI_SERVICE}" "${LOKI_LOCAL_PORT}" "${LOKI_SERVICE_PORT}" "loki"
  start_port_forward "${TRACING_NAMESPACE}" "${TEMPO_SERVICE}" "${TEMPO_LOCAL_PORT}" "${TEMPO_SERVICE_PORT}" "tempo"

  prepare_r10_fixtures
  run_r10
  run_r11
  run_prom_assertions
  run_loki_assertions
  run_tempo_assertions
  write_report
}

main "$@"
