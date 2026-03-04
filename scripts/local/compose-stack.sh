#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RAW_CMD="${1:-}"
DEPLOY_MODE="${DEPLOY_MODE:-source}"
CMD="${RAW_CMD}"

case "${RAW_CMD}" in
  up-source)
    DEPLOY_MODE="source"
    CMD="up"
    ;;
  restart-source)
    DEPLOY_MODE="source"
    CMD="restart"
    ;;
  up-delivery)
    DEPLOY_MODE="delivery"
    CMD="up"
    ;;
  restart-delivery)
    DEPLOY_MODE="delivery"
    CMD="restart"
    ;;
  pull-delivery)
    DEPLOY_MODE="delivery"
    CMD="pull"
    ;;
esac

if [[ "${DEPLOY_MODE}" != "source" && "${DEPLOY_MODE}" != "delivery" ]]; then
  echo "DEPLOY_MODE 非法: ${DEPLOY_MODE}，仅支持 source 或 delivery" >&2
  exit 1
fi

DEFAULT_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.stack.yml"
DEFAULT_ENV_FILE="$PROJECT_ROOT/.env.compose"
DEFAULT_ENV_EXAMPLE="$PROJECT_ROOT/.env.compose.example"

if [[ "${DEPLOY_MODE}" == "delivery" ]]; then
  DEFAULT_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.delivery.yml"
  DEFAULT_ENV_FILE="$PROJECT_ROOT/.env.delivery"
  DEFAULT_ENV_EXAMPLE="$PROJECT_ROOT/.env.delivery.example"
fi

COMPOSE_FILE="${COMPOSE_FILE:-$DEFAULT_COMPOSE_FILE}"
ENV_FILE="${ENV_FILE:-$DEFAULT_ENV_FILE}"
CURL_IMAGE="${CURL_IMAGE:-curlimages/curl:8.7.1}"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$DEFAULT_ENV_EXAMPLE" "$ENV_FILE"
  echo "已创建 $ENV_FILE（可按需调整端口和账号）"
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${DB_NAME:=ljwx_platform}"
: "${DB_PASSWORD:=}"
: "${ALLOW_WEAK_PASSWORD:=0}"
: "${BACKEND_PORT:=18080}"
: "${ADMIN_PORT:=18081}"
: "${SCREEN_PORT:=18082}"
: "${COMPOSE_NETWORK:=ljwx-platform-stack-net}"
: "${BACKEND_IMAGE:=}"
: "${ADMIN_IMAGE:=}"
: "${SCREEN_IMAGE:=}"

should_validate_password="0"
case "${CMD}" in
  up|restart|smoke|seed|e2e)
    should_validate_password="1"
    ;;
esac

if [[ "${should_validate_password}" == "1" && "$ALLOW_WEAK_PASSWORD" != "1" ]]; then
  if [[ -z "$DB_PASSWORD" || "$DB_PASSWORD" == "postgres" || "$DB_PASSWORD" == "123456" || "$DB_PASSWORD" == *"CHANGE_ME"* || ${#DB_PASSWORD} -lt 12 ]]; then
    echo "检测到数据库密码不安全（为空/默认/过短）。请在 ${ENV_FILE} 设置强密码，或临时设置 ALLOW_WEAK_PASSWORD=1（不推荐）。" >&2
    exit 1
  fi
fi

validate_delivery_images() {
  local missing=0
  for image_var in BACKEND_IMAGE ADMIN_IMAGE SCREEN_IMAGE; do
    local image_ref
    image_ref="${!image_var:-}"
    if [[ -z "${image_ref}" || "${image_ref}" == *"CHANGE_ME"* ]]; then
      echo "交付模式缺少有效镜像引用: ${image_var}。请在 ${ENV_FILE} 设置不可变 tag 或 digest。" >&2
      missing=1
    fi
  done

  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

compose_up() {
  if [[ "${DEPLOY_MODE}" == "delivery" ]]; then
    validate_delivery_images
    compose pull
    compose up -d --no-build
    return
  fi
  compose up -d --build
}

compose_restart() {
  if [[ "${DEPLOY_MODE}" == "delivery" ]]; then
    validate_delivery_images
    compose pull
    compose up -d --no-build --force-recreate
    return
  fi
  compose up -d --build --force-recreate
}

http_probe() {
  local url="$1"
  docker run --rm --network "$COMPOSE_NETWORK" "$CURL_IMAGE" -fsS "$url" >/dev/null
}

wait_http() {
  local name="$1"
  local url="$2"
  local retries="${3:-120}"
  local delay="${4:-2}"
  local i

  for ((i = 1; i <= retries; i += 1)); do
    if http_probe "$url"; then
      echo "$name 已就绪: $url"
      return 0
    fi
    sleep "$delay"
  done

  echo "$name 健康检查超时: $url" >&2
  return 1
}

seed_fixtures() {
  local postgres_container_id
  postgres_container_id="$(compose ps -q postgres)"
  if [[ -z "$postgres_container_id" ]]; then
    echo "未找到 postgres 容器，请先执行 up" >&2
    exit 1
  fi

  POSTGRES_CONTAINER_ID="$postgres_container_id" DB_NAME="$DB_NAME" DB_USERNAME="${DB_USERNAME:-postgres}" \
    bash "$PROJECT_ROOT/scripts/e2e/seed-fixtures.sh"
}

run_e2e() {
  if [[ "${DEPLOY_MODE}" == "delivery" ]]; then
    validate_delivery_images
  fi
  seed_fixtures
  K6_FORCE_DOCKER="${K6_FORCE_DOCKER:-1}" \
  K6_DOCKER_NETWORK="${K6_DOCKER_NETWORK:-$COMPOSE_NETWORK}" \
  BASE_URL="${BASE_URL:-http://backend:8080}" \
  TENANT_A_USER="${TENANT_A_USER:-admin}" \
  TENANT_A_PASS="${TENANT_A_PASS:-Admin@12345}" \
  TENANT_B_USER="${TENANT_B_USER:-tenantB_admin}" \
  TENANT_B_PASS="${TENANT_B_PASS:-Admin@12345}" \
  LOGIN_PATH="${LOGIN_PATH:-/api/auth/login}" \
  FORBIDDEN_PATH="${FORBIDDEN_PATH:-/api/users}" \
  RESOURCE_LIST_PATH="${RESOURCE_LIST_PATH:-/api/v1/menus}" \
  bash "$PROJECT_ROOT/scripts/gates/gate-e2e.sh"
}

case "$CMD" in
  up)
    compose_up
    ;;
  down)
    compose down -v
    ;;
  restart)
    compose_restart
    ;;
  pull)
    if [[ "${DEPLOY_MODE}" != "delivery" ]]; then
      echo "pull 仅用于交付模式。请设置 DEPLOY_MODE=delivery 或使用 pull-delivery。" >&2
      exit 1
    fi
    validate_delivery_images
    compose pull
    ;;
  ps|status)
    compose ps
    ;;
  logs)
    compose logs -f --tail 200
    ;;
  smoke)
    wait_http "backend" "http://backend:8080/actuator/health" 180 2
    wait_http "admin" "http://admin/" 60 2
    wait_http "screen" "http://screen/" 60 2
    ;;
  seed)
    seed_fixtures
    ;;
  e2e)
    run_e2e
    ;;
  *)
    cat <<'EOF'
用法:
  # 源码构建模式（默认）
  bash scripts/local/compose-stack.sh up            # 构建并启动 5 个服务
  bash scripts/local/compose-stack.sh restart

  # 交付件模式（仅镜像拉取，不本地构建）
  DEPLOY_MODE=delivery bash scripts/local/compose-stack.sh up
  DEPLOY_MODE=delivery bash scripts/local/compose-stack.sh pull
  bash scripts/local/compose-stack.sh up-delivery
  bash scripts/local/compose-stack.sh restart-delivery

  # 通用操作
  bash scripts/local/compose-stack.sh smoke         # 健康检查 backend/admin/screen
  bash scripts/local/compose-stack.sh seed          # 写入 e2e 夹具数据
  bash scripts/local/compose-stack.sh e2e           # 执行 R10 e2e 闭环
  bash scripts/local/compose-stack.sh status        # 查看状态
  bash scripts/local/compose-stack.sh logs          # 查看日志
  bash scripts/local/compose-stack.sh down          # 停止并清理卷
EOF
    ;;
esac
