#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
KUSTOMIZE_DIR="${KUSTOMIZE_DIR:-$PROJECT_ROOT/deploy/k3s/artifact}"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env.k3s.delivery}"
EXAMPLE_ENV_FILE="$PROJECT_ROOT/.env.k3s.delivery.example"

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${EXAMPLE_ENV_FILE}" "${ENV_FILE}"
  echo "已创建 ${ENV_FILE}，请先填写镜像和凭据后重试。"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${NAMESPACE:=ljwx-platform}"
: "${RUNTIME_CONFIG_NAME:=ljwx-platform-runtime}"
: "${DB_SECRET_NAME:=ljwx-platform-db}"
: "${IMAGE_PULL_SECRET_NAME:=harbor-pull}"
: "${SPRING_PROFILES_ACTIVE:=prod}"
: "${DB_HOST:=postgres-lb.infra.svc.cluster.local}"
: "${DB_PORT:=5432}"
: "${DB_NAME:=ljwx_platform}"
: "${REDIS_HOST:=redis-lb.infra.svc.cluster.local}"
: "${REDIS_PORT:=6379}"
: "${DB_USERNAME:=postgres}"
: "${DB_PASSWORD:=}"
: "${REDIS_PASSWORD:=}"
: "${JWT_SECRET:=}"
: "${BACKEND_IMAGE:=}"
: "${ADMIN_IMAGE:=}"
: "${SCREEN_IMAGE:=}"
: "${MANAGE_DB_SECRET:=1}"
: "${MANAGE_PULL_SECRET:=0}"
: "${REGISTRY_SERVER:=}"
: "${REGISTRY_USERNAME:=}"
: "${REGISTRY_PASSWORD:=}"
: "${ROLLOUT_TIMEOUT:=300s}"
: "${BACKEND_SERVICE_NAME:=ljwx-platform}"
: "${ADMIN_SERVICE_NAME:=ljwx-platform-admin-ui}"
: "${SCREEN_SERVICE_NAME:=ljwx-platform-screen}"
: "${BACKEND_LOCAL_PORT:=18080}"
: "${ADMIN_LOCAL_PORT:=18081}"
: "${SCREEN_LOCAL_PORT:=18082}"
: "${SERVICE_PORT:=80}"
: "${TENANT_A_USER:=admin}"
: "${TENANT_A_PASS:=Admin@12345}"
: "${TENANT_B_USER:=tenantB_admin}"
: "${TENANT_B_PASS:=Admin@12345}"
: "${LOGIN_PATH:=/api/auth/login}"
: "${FORBIDDEN_PATH:=/api/users}"
: "${RESOURCE_LIST_PATH:=/api/v1/menus}"
: "${K8S_PSQL_IMAGE:=postgres:16-alpine}"

PORT_FORWARD_PIDS=()

cleanup_port_forwards() {
  local pid
  for pid in "${PORT_FORWARD_PIDS[@]:-}"; do
    if [[ -n "${pid}" ]]; then
      kill "${pid}" >/dev/null 2>&1 || true
      wait "${pid}" >/dev/null 2>&1 || true
    fi
  done
  PORT_FORWARD_PIDS=()
}

trap cleanup_port_forwards EXIT

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "缺少依赖命令: ${cmd}" >&2
    exit 1
  fi
}

validate_images() {
  local missing=0
  for image_var in BACKEND_IMAGE ADMIN_IMAGE SCREEN_IMAGE; do
    local image_ref
    image_ref="${!image_var:-}"
    if [[ -z "${image_ref}" || "${image_ref}" == *"CHANGE_ME"* ]]; then
      echo "缺少有效镜像引用: ${image_var}，请在 ${ENV_FILE} 中设置。" >&2
      missing=1
    fi
  done

  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

validate_db_secret_inputs() {
  if [[ "${MANAGE_DB_SECRET}" != "1" ]]; then
    return
  fi

  if [[ -z "${DB_PASSWORD}" || "${DB_PASSWORD}" == *"CHANGE_ME"* || ${#DB_PASSWORD} -lt 12 ]]; then
    echo "DB_PASSWORD 不安全或未设置，请在 ${ENV_FILE} 中配置强口令。" >&2
    exit 1
  fi

  if [[ -z "${JWT_SECRET}" || "${JWT_SECRET}" == *"CHANGE_ME"* || ${#JWT_SECRET} -lt 32 ]]; then
    if command -v openssl >/dev/null 2>&1; then
      JWT_SECRET="$(openssl rand -hex 32)"
      echo "检测到 JWT_SECRET 未设置，已生成临时随机值并用于本次部署。"
    else
      echo "JWT_SECRET 未设置且未安装 openssl，无法自动生成。" >&2
      exit 1
    fi
  fi
}

ensure_namespace() {
  kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}" >/dev/null
}

apply_runtime_config() {
  kubectl -n "${NAMESPACE}" create configmap "${RUNTIME_CONFIG_NAME}" \
    --from-literal=SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE}" \
    --from-literal=SPRING_FLYWAY_OUT_OF_ORDER=false \
    --from-literal=SPRING_FLYWAY_IGNORE_MIGRATION_PATTERNS='*:future,*:ignored' \
    --from-literal=DB_HOST="${DB_HOST}" \
    --from-literal=DB_PORT="${DB_PORT}" \
    --from-literal=DB_NAME="${DB_NAME}" \
    --from-literal=REDIS_HOST="${REDIS_HOST}" \
    --from-literal=REDIS_PORT="${REDIS_PORT}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

apply_db_secret() {
  if [[ "${MANAGE_DB_SECRET}" != "1" ]]; then
    if ! kubectl -n "${NAMESPACE}" get secret "${DB_SECRET_NAME}" >/dev/null 2>&1; then
      echo "MANAGE_DB_SECRET=0 且缺少 secret/${DB_SECRET_NAME}，无法继续部署。" >&2
      exit 1
    fi
    return
  fi

  kubectl -n "${NAMESPACE}" create secret generic "${DB_SECRET_NAME}" \
    --from-literal=DB_USERNAME="${DB_USERNAME}" \
    --from-literal=DB_PASSWORD="${DB_PASSWORD}" \
    --from-literal=REDIS_PASSWORD="${REDIS_PASSWORD}" \
    --from-literal=JWT_SECRET="${JWT_SECRET}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

apply_pull_secret() {
  if [[ "${MANAGE_PULL_SECRET}" != "1" ]]; then
    return
  fi

  local registry_host
  registry_host="${REGISTRY_SERVER}"
  if [[ -z "${registry_host}" ]]; then
    registry_host="${BACKEND_IMAGE%%/*}"
  fi

  if [[ -z "${registry_host}" || -z "${REGISTRY_USERNAME}" || -z "${REGISTRY_PASSWORD}" ]]; then
    echo "MANAGE_PULL_SECRET=1 需要 REGISTRY_SERVER/REGISTRY_USERNAME/REGISTRY_PASSWORD。" >&2
    exit 1
  fi

  kubectl -n "${NAMESPACE}" create secret docker-registry "${IMAGE_PULL_SECRET_NAME}" \
    --docker-server="${registry_host}" \
    --docker-username="${REGISTRY_USERNAME}" \
    --docker-password="${REGISTRY_PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl -n "${NAMESPACE}" patch serviceaccount default \
    --type=merge \
    -p "{\"imagePullSecrets\":[{\"name\":\"${IMAGE_PULL_SECRET_NAME}\"}]}"
}

apply_workloads() {
  kubectl -n "${NAMESPACE}" apply -k "${KUSTOMIZE_DIR}"

  kubectl -n "${NAMESPACE}" set image deployment/ljwx-platform \
    ljwx-platform="${BACKEND_IMAGE}"
  kubectl -n "${NAMESPACE}" set image deployment/ljwx-platform-admin-ui \
    ljwx-platform-admin-ui="${ADMIN_IMAGE}"
  kubectl -n "${NAMESPACE}" set image deployment/ljwx-platform-screen \
    ljwx-platform-screen="${SCREEN_IMAGE}"

  kubectl -n "${NAMESPACE}" rollout status deployment/ljwx-platform --timeout="${ROLLOUT_TIMEOUT}"
  kubectl -n "${NAMESPACE}" rollout status deployment/ljwx-platform-admin-ui --timeout="${ROLLOUT_TIMEOUT}"
  kubectl -n "${NAMESPACE}" rollout status deployment/ljwx-platform-screen --timeout="${ROLLOUT_TIMEOUT}"
}

print_status() {
  kubectl -n "${NAMESPACE}" get deploy,svc,pods -o wide
}

print_logs() {
  kubectl -n "${NAMESPACE}" logs deploy/ljwx-platform --tail=200
}

decode_secret_value() {
  local secret_name="$1"
  local key="$2"
  kubectl -n "${NAMESPACE}" get secret "${secret_name}" -o "jsonpath={.data.${key}}" 2>/dev/null | base64 -d 2>/dev/null || true
}

resolve_db_credentials() {
  if ! kubectl -n "${NAMESPACE}" get secret "${DB_SECRET_NAME}" >/dev/null 2>&1; then
    return
  fi

  if [[ "${MANAGE_DB_SECRET}" != "1" || -z "${DB_PASSWORD}" || "${DB_PASSWORD}" == *"CHANGE_ME"* ]]; then
    local secret_username secret_password
    secret_username="$(decode_secret_value "${DB_SECRET_NAME}" DB_USERNAME)"
    secret_password="$(decode_secret_value "${DB_SECRET_NAME}" DB_PASSWORD)"

    if [[ -n "${secret_username}" ]]; then
      DB_USERNAME="${secret_username}"
    fi
    if [[ -n "${secret_password}" ]]; then
      DB_PASSWORD="${secret_password}"
    fi
  fi
}

start_port_forward() {
  local service_name="$1"
  local local_port="$2"
  local service_port="$3"
  local health_url="$4"
  local log_file
  log_file="$(mktemp "/tmp/${service_name}.port-forward.XXXXXX.log")"

  kubectl -n "${NAMESPACE}" port-forward "svc/${service_name}" "${local_port}:${service_port}" >"${log_file}" 2>&1 &
  local pf_pid=$!
  PORT_FORWARD_PIDS+=("${pf_pid}")

  local i
  for i in $(seq 1 120); do
    if curl -fsS "${health_url}" >/dev/null 2>&1; then
      echo "${service_name} 已通过 port-forward 就绪: ${health_url}"
      return 0
    fi
    if ! kill -0 "${pf_pid}" >/dev/null 2>&1; then
      echo "port-forward 进程异常退出: svc/${service_name}" >&2
      cat "${log_file}" >&2 || true
      return 1
    fi
    sleep 2
  done

  echo "port-forward 健康检查超时: svc/${service_name} -> ${health_url}" >&2
  cat "${log_file}" >&2 || true
  return 1
}

run_smoke() {
  require_command kubectl
  require_command curl
  cleanup_port_forwards

  start_port_forward "${BACKEND_SERVICE_NAME}" "${BACKEND_LOCAL_PORT}" "${SERVICE_PORT}" "http://127.0.0.1:${BACKEND_LOCAL_PORT}/actuator/health"
  start_port_forward "${ADMIN_SERVICE_NAME}" "${ADMIN_LOCAL_PORT}" "${SERVICE_PORT}" "http://127.0.0.1:${ADMIN_LOCAL_PORT}/"
  start_port_forward "${SCREEN_SERVICE_NAME}" "${SCREEN_LOCAL_PORT}" "${SERVICE_PORT}" "http://127.0.0.1:${SCREEN_LOCAL_PORT}/"

  echo "k3s smoke 检查通过"
  cleanup_port_forwards
}

seed_fixtures() {
  require_command kubectl
  resolve_db_credentials

  if [[ -z "${DB_PASSWORD}" || "${DB_PASSWORD}" == *"CHANGE_ME"* ]]; then
    echo "缺少可用 DB_PASSWORD，无法在 k3s 集群内写入 E2E 夹具" >&2
    exit 1
  fi

  PSQL_MODE=kubectl \
  K8S_NAMESPACE="${NAMESPACE}" \
  K8S_PSQL_IMAGE="${K8S_PSQL_IMAGE}" \
  DB_HOST="${DB_HOST}" \
  DB_PORT="${DB_PORT}" \
  DB_NAME="${DB_NAME}" \
  DB_USERNAME="${DB_USERNAME}" \
  DB_PASSWORD="${DB_PASSWORD}" \
  bash "${PROJECT_ROOT}/scripts/e2e/seed-fixtures.sh"
}

run_e2e() {
  require_command kubectl
  require_command curl
  cleanup_port_forwards
  seed_fixtures
  start_port_forward "${BACKEND_SERVICE_NAME}" "${BACKEND_LOCAL_PORT}" "${SERVICE_PORT}" "http://127.0.0.1:${BACKEND_LOCAL_PORT}/actuator/health"

  K6_FORCE_DOCKER="${K6_FORCE_DOCKER:-0}" \
  BASE_URL="http://127.0.0.1:${BACKEND_LOCAL_PORT}" \
  TENANT_A_USER="${TENANT_A_USER}" \
  TENANT_A_PASS="${TENANT_A_PASS}" \
  TENANT_B_USER="${TENANT_B_USER}" \
  TENANT_B_PASS="${TENANT_B_PASS}" \
  LOGIN_PATH="${LOGIN_PATH}" \
  FORBIDDEN_PATH="${FORBIDDEN_PATH}" \
  RESOURCE_LIST_PATH="${RESOURCE_LIST_PATH}" \
  bash "${PROJECT_ROOT}/scripts/gates/gate-e2e.sh"

  cleanup_port_forwards
}

run_perf() {
  require_command kubectl
  require_command curl
  cleanup_port_forwards
  start_port_forward "${BACKEND_SERVICE_NAME}" "${BACKEND_LOCAL_PORT}" "${SERVICE_PORT}" "http://127.0.0.1:${BACKEND_LOCAL_PORT}/actuator/health"

  BASE_URL="http://127.0.0.1:${BACKEND_LOCAL_PORT}" \
  TENANT_A_USER="${TENANT_A_USER}" \
  TENANT_A_PASS="${TENANT_A_PASS}" \
  LOGIN_PATH="${LOGIN_PATH}" \
  bash "${PROJECT_ROOT}/scripts/gates/gate-perf.sh"

  cleanup_port_forwards
}

run_system_tests() {
  run_smoke
  run_e2e
  run_perf
}

run_apply() {
  require_command kubectl
  validate_images
  validate_db_secret_inputs
  ensure_namespace
  apply_runtime_config
  apply_db_secret
  apply_pull_secret
  apply_workloads
  print_status
}

CMD="${1:-}"
case "${CMD}" in
  apply)
    run_apply
    ;;
  status)
    require_command kubectl
    print_status
    ;;
  logs)
    require_command kubectl
    print_logs
    ;;
  smoke)
    run_smoke
    ;;
  seed)
    seed_fixtures
    ;;
  e2e)
    run_e2e
    ;;
  perf)
    run_perf
    ;;
  system-test)
    run_system_tests
    ;;
  render)
    require_command kubectl
    kubectl kustomize "${KUSTOMIZE_DIR}"
    ;;
  delete)
    require_command kubectl
    kubectl delete namespace "${NAMESPACE}" --ignore-not-found
    ;;
  *)
    cat <<'EOF'
用法:
  bash scripts/local/k3s-delivery.sh apply     # 按交付镜像部署 backend/admin-ui/screen
  bash scripts/local/k3s-delivery.sh status    # 查看部署状态
  bash scripts/local/k3s-delivery.sh logs      # 查看 backend 日志
  bash scripts/local/k3s-delivery.sh smoke     # 通过 port-forward 做 backend/admin/screen 健康检查
  bash scripts/local/k3s-delivery.sh seed      # 在集群内写入 E2E 夹具
  bash scripts/local/k3s-delivery.sh e2e       # 通过 port-forward 执行 R10 E2E
  bash scripts/local/k3s-delivery.sh perf      # 通过 port-forward 执行 R11 基线
  bash scripts/local/k3s-delivery.sh system-test  # 串行执行 smoke + e2e + perf
  bash scripts/local/k3s-delivery.sh render    # 渲染 kustomize 清单
  bash scripts/local/k3s-delivery.sh delete    # 删除命名空间（慎用）
EOF
    ;;
esac
