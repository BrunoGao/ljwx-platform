#!/usr/bin/env bash
set -euo pipefail

SYNC_WEBHOOK_URL="${SYNC_WEBHOOK_URL:-http://127.0.0.1:8088}"
SYNC_HMAC_SECRET="${SYNC_HMAC_SECRET:-}"
SYNC_BEARER_TOKEN="${SYNC_BEARER_TOKEN:-}"

if [ -z "${SYNC_HMAC_SECRET}" ] || [ -z "${SYNC_BEARER_TOKEN}" ]; then
  echo "[错误] 请设置 SYNC_HMAC_SECRET 和 SYNC_BEARER_TOKEN" >&2
  exit 1
fi

TS="$(date +%s)"
NOW_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
SHORT_SHA_DEFAULT="$(date +%s | sha256sum | cut -c1-7)"
SHORT_SHA="${SHORT_SHA:-$SHORT_SHA_DEFAULT}"
EVENT_ID="${EVENT_ID:-manual-${TS}}"
REPOSITORY="${REPOSITORY:-brunogao/ljwx-platform}"
IMAGE="${IMAGE:-ghcr.io/brunogao/ljwx-platform/ljwx-platform}"
GIT_SHA="${GIT_SHA:-${SHORT_SHA}000000000000000000000000000000000000}"
BRANCH="${BRANCH:-main}"
DIGEST="${DIGEST:-sha256:1111111111111111111111111111111111111111111111111111111111111111}"
COMPONENT="${COMPONENT:-backend}"
TAGS_JSON="${TAGS_JSON:-[\"sha-${SHORT_SHA}\",\"branch-${BRANCH}\"]}"

BODY="$(jq -nc \
  --arg event_id "${EVENT_ID}" \
  --arg repository "${REPOSITORY}" \
  --arg image "${IMAGE}" \
  --arg git_sha "${GIT_SHA}" \
  --arg short_sha "${SHORT_SHA}" \
  --arg branch "${BRANCH}" \
  --arg digest "${DIGEST}" \
  --arg component "${COMPONENT}" \
  --arg triggered_at "${NOW_UTC}" \
  --argjson tags "${TAGS_JSON}" \
  '{
    event_id: $event_id,
    repository: $repository,
    image: $image,
    git_sha: $git_sha,
    short_sha: $short_sha,
    branch: $branch,
    digest: $digest,
    tags: $tags,
    component: $component,
    triggered_at: $triggered_at
  }')"

SIG="$(printf '%s.%s' "${TS}" "${BODY}" | openssl dgst -sha256 -hmac "${SYNC_HMAC_SECRET}" -binary | xxd -p -c 256)"

curl -fsS -X POST "${SYNC_WEBHOOK_URL}/sync" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SYNC_BEARER_TOKEN}" \
  -H "X-Sync-Timestamp: ${TS}" \
  -H "X-Sync-Signature: sha256=${SIG}" \
  -d "${BODY}"

echo

echo "[完成] webhook 已发送到 ${SYNC_WEBHOOK_URL}/sync"
