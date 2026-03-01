#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# wait-github-workflow.sh — 轮询 GitHub Actions 直到指定 workflow 完成
#
# 用法:
#   bash scripts/wait-github-workflow.sh \
#     --repo owner/repo \
#     --sha <full-commit-sha> \
#     --workflow build-and-notify.yml
#
# 可选参数:
#   --timeout-sec 3600     总超时（默认 3600s）
#   --interval-sec 15      轮询间隔（默认 15s）
#
# 依赖:
#   gh CLI（已 `gh auth login`）或 GITHUB_TOKEN 环境变量（repo/actions:read 权限）
#
# 退出码:
#   0  — success
#   2  — 参数错误
#   3  — 超时
#   10 — workflow 以非 success 结论结束
# ═══════════════════════════════════════════════════════════
set -euo pipefail

# ── Argument parsing ───────────────────────────────────────
REPO=""
SHA=""
WORKFLOW=""
TIMEOUT_SEC=3600
INTERVAL_SEC=15

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)         REPO="$2";         shift 2 ;;
    --sha)          SHA="$2";          shift 2 ;;
    --workflow)     WORKFLOW="$2";     shift 2 ;;
    --timeout-sec)  TIMEOUT_SEC="$2";  shift 2 ;;
    --interval-sec) INTERVAL_SEC="$2"; shift 2 ;;
    *) echo "[wait-workflow] Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "$REPO" || -z "$SHA" || -z "$WORKFLOW" ]]; then
  echo "Usage: $0 --repo owner/repo --sha <sha> --workflow <workflow_file>"
  echo "       (e.g. --workflow build-and-notify.yml)"
  exit 2
fi

# ── Helpers ────────────────────────────────────────────────
get_run_id() {
  # 返回该 workflow 在该 commit 上最新一条 run 的 id；未找到返回空字符串
  gh api \
    -H "Accept: application/vnd.github+json" \
    "/repos/${REPO}/actions/workflows/${WORKFLOW}/runs?per_page=50" \
    --jq ".workflow_runs[] | select(.head_sha==\"${SHA}\") | .id" \
    2>/dev/null | head -n 1 || true
}

get_run_info() {
  local run_id="$1"
  gh api \
    -H "Accept: application/vnd.github+json" \
    "/repos/${REPO}/actions/runs/${run_id}" \
    --jq '{status:.status,conclusion:.conclusion,url:.html_url}' \
    2>/dev/null || true
}

# ── Main loop ──────────────────────────────────────────────
echo "[CI] Waiting for workflow '${WORKFLOW}' on ${REPO} @ ${SHA:0:12}..."
start_ts=$(date +%s)
run_id=""

while true; do
  elapsed=$(( $(date +%s) - start_ts ))
  if (( elapsed >= TIMEOUT_SEC )); then
    echo "[CI] TIMEOUT after ${TIMEOUT_SEC}s — sha=${SHA:0:12}"
    exit 3
  fi

  # ── Find run id ──
  if [[ -z "$run_id" ]]; then
    run_id="$(get_run_id)"
    if [[ -z "$run_id" ]]; then
      echo "[CI] Run not found yet (elapsed ${elapsed}s) — retrying in ${INTERVAL_SEC}s..."
      sleep "$INTERVAL_SEC"
      continue
    fi
    echo "[CI] Found run_id=${run_id}"
  fi

  # ── Poll status ──
  info="$(get_run_info "$run_id")"
  if [[ -z "$info" ]]; then
    echo "[CI] Failed to fetch run info — retrying in ${INTERVAL_SEC}s..."
    sleep "$INTERVAL_SEC"
    continue
  fi

  status="$(echo "$info"     | jq -r '.status')"
  conclusion="$(echo "$info" | jq -r '.conclusion')"
  url="$(echo "$info"        | jq -r '.url')"

  echo "[CI] status=${status} conclusion=${conclusion} elapsed=${elapsed}s"

  if [[ "$status" == "completed" ]]; then
    if [[ "$conclusion" == "success" ]]; then
      echo "[CI] PASSED — ${url}"
      exit 0
    else
      echo "[CI] FAILED — conclusion=${conclusion}"
      echo "[CI] URL: ${url}"
      exit 10
    fi
  fi

  sleep "$INTERVAL_SEC"
done
