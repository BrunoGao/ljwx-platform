#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq first." >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_DIR="docs/reports/data/phases"
HISTORY_DIR="docs/reports/data/history"
OUT="docs/reports/data/summary.json"
mkdir -p "$PHASE_DIR" "$HISTORY_DIR"

commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
remote="$(git config --get remote.origin.url 2>/dev/null || true)"
owner="unknown"
repo="unknown"
default_branch="master"
if [[ "$remote" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
  owner="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
fi

run_id="${GITHUB_RUN_ID:-local}"
run_attempt="${GITHUB_RUN_ATTEMPT:-1}"
workflow_name="${GITHUB_WORKFLOW:-gate-local}"
run_url=""
if [[ "$owner" != "unknown" && "$repo" != "unknown" && "$run_id" != "local" ]]; then
  run_url="https://github.com/${owner}/${repo}/actions/runs/${run_id}"
fi

phases_tmp="$(mktemp)"
echo '[]' >"$phases_tmp"

for i in $(seq 0 32); do
  phase="$(printf '%02d' "$i")"
  file="$PHASE_DIR/phase-$phase.json"
  if [[ -f "$file" ]]; then
    item="$(jq -c '
      {
        phase,
        status,
        pass_rate: .summary.pass_rate,
        critical: .summary.critical,
        warnings: .summary.warnings,
        timestamp,
        git_commit: .git.commit,
        r09_status: ((.rules // []) | map(select(.id=="R09")) | .[0].status // "PENDING"),
        gate_status: ((.rules // []) | map({key: .id, value: .status}) | from_entries)
      }' "$file")"
  else
    item="$(jq -nc --arg p "$phase" '{phase:$p,status:"PENDING",pass_rate:0,critical:0,warnings:0,timestamp:"",git_commit:"",r09_status:"PENDING",gate_status:{}}')"
  fi
  jq --argjson item "$item" '. + [$item]' "$phases_tmp" >"$phases_tmp.next" && mv "$phases_tmp.next" "$phases_tmp"
done

history_tmp="$(mktemp)"
echo '[]' >"$history_tmp"
if ls "$HISTORY_DIR"/*.json >/dev/null 2>&1; then
  ls -1t "$HISTORY_DIR"/*.json | head -n 50 | while read -r f; do
    entry="$(jq -c '
      {
        timestamp,
        phase,
        status,
        pass_rate: .summary.pass_rate,
        git_commit: .git.commit,
        critical: .summary.critical,
        warnings: .summary.warnings,
        run_id: (.ci.run_id // null),
        run_url: (.ci.run_url // null)
      }' "$f" 2>/dev/null || echo '{}')"
    jq --argjson e "$entry" '. + [$e]' "$history_tmp" >"$history_tmp.next" && mv "$history_tmp.next" "$history_tmp"
  done
fi

totals="$(jq -c '
  {
    pass: (map(select(.status=="PASS"))|length),
    fail: (map(select(.status=="FAIL"))|length),
    pending: (map(select(.status=="PENDING"))|length),
    critical: (map(.critical // 0)|add),
    warnings: (map(.warnings // 0)|add)
  }
' "$phases_tmp")"

jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg owner "$owner" \
  --arg name "$repo" \
  --arg default_branch "$default_branch" \
  --arg branch "$branch" \
  --arg commit "$commit" \
  --arg run_id "$run_id" \
  --arg run_attempt "$run_attempt" \
  --arg workflow_name "$workflow_name" \
  --arg run_url "$run_url" \
  --argjson totals "$totals" \
  --slurpfile phases "$phases_tmp" \
  --slurpfile history "$history_tmp" \
  '{
    generated_at: $ts,
    repo: {owner: $owner, name: $name, default_branch: $default_branch},
    git: {branch: $branch, commit: $commit, short: $commit},
    ci: {
      run_id: (if $run_id == "local" then null else ($run_id | tonumber) end),
      run_attempt: ($run_attempt | tonumber),
      workflow: $workflow_name,
      run_url: (if $run_url == "" then null else $run_url end)
    },
    totals: $totals,
    phases: $phases[0],
    history: $history[0]
  }' >"$OUT"

echo "$OUT"
