#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.test.yml"
BASE_URL="${BASE_URL:-http://localhost:8080}"
HEALTH_PATH="${HEALTH_PATH:-/actuator/health}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
START_APP_CONTAINER="${START_APP_CONTAINER:-true}"

usage() {
  cat <<USAGE
Usage:
  bash scripts/setup-test-env.sh <up|down|clean|status>

Commands:
  up      Start test services (mysql/redis/app by default) and wait health when app is started
  down    Stop test services
  clean   Stop services and remove volumes
  status  Show service status

Env:
  START_APP_CONTAINER=true|false   Start app service from compose (default true)
  BASE_URL=http://localhost:8080   Health check base URL
  HEALTH_PATH=/actuator/health     Health endpoint path
  WAIT_SECONDS=180                 Health wait timeout
USAGE
}

resolve_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
    return
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
    return
  fi

  echo "docker compose/docker-compose is required" >&2
  exit 1
}

wait_http_ready() {
  local url="$1"
  local max_seconds="$2"
  local elapsed=0

  while (( elapsed < max_seconds )); do
    if curl -fsS "${url}" >/dev/null 2>&1; then
      echo "[setup-test-env] health check passed: ${url}"
      return 0
    fi
    sleep 3
    elapsed=$((elapsed + 3))
  done

  echo "[setup-test-env] health check timeout after ${max_seconds}s: ${url}" >&2
  return 1
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local action="$1"
  local compose
  compose="$(resolve_compose)"

  case "${action}" in
    up)
      echo "[setup-test-env] starting services from ${COMPOSE_FILE}"
      if [[ "$START_APP_CONTAINER" == "true" ]]; then
        ${compose} -f "${COMPOSE_FILE}" up -d mysql redis app
        wait_http_ready "${BASE_URL}${HEALTH_PATH}" "${WAIT_SECONDS}"
        echo "[setup-test-env] BASE_URL=${BASE_URL}"
      else
        ${compose} -f "${COMPOSE_FILE}" up -d mysql redis
        echo "[setup-test-env] started mysql/redis only (START_APP_CONTAINER=false)"
      fi
      ;;
    down)
      ${compose} -f "${COMPOSE_FILE}" down
      ;;
    clean)
      ${compose} -f "${COMPOSE_FILE}" down -v
      ;;
    status)
      ${compose} -f "${COMPOSE_FILE}" ps
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
