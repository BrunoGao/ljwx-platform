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
: "${LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD:=}"
: "${LJWX_BOOTSTRAP_USER_IMPORT_INITIAL_PASSWORD:=}"
: "${BACKEND_IMAGE:=}"
: "${ADMIN_IMAGE:=}"
: "${SCREEN_IMAGE:=}"
: "${MANAGE_DB_SECRET:=1}"
: "${MANAGE_PULL_SECRET:=0}"
: "${REGISTRY_SERVER:=}"
: "${REGISTRY_USERNAME:=}"
: "${REGISTRY_PASSWORD:=}"
: "${ROLLOUT_TIMEOUT:=300s}"

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

  if [[ -z "${LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD}" || "${LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD}" == *"CHANGE_ME"* ]]; then
    echo "LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD 未设置，请在 ${ENV_FILE} 中配置强口令。" >&2
    exit 1
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
    --from-literal=LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD="${LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD}" \
    --from-literal=LJWX_BOOTSTRAP_USER_IMPORT_INITIAL_PASSWORD="${LJWX_BOOTSTRAP_USER_IMPORT_INITIAL_PASSWORD}" \
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
  bash scripts/local/k3s-delivery.sh render    # 渲染 kustomize 清单
  bash scripts/local/k3s-delivery.sh delete    # 删除命名空间（慎用）
EOF
    ;;
esac
