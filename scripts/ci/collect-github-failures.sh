#!/usr/bin/env bash
set -euo pipefail

REPO=""
WORKFLOW=""
SHA=""
RUN_ID=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)       REPO="$2"; shift 2 ;;
    --workflow)   WORKFLOW="$2"; shift 2 ;;
    --sha)        SHA="$2"; shift 2 ;;
    --run-id)     RUN_ID="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "[gh-collect] Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$REPO" || -z "$OUTPUT_DIR" ]]; then
  echo "[gh-collect] Usage: $0 --repo owner/repo --output-dir <dir> [--workflow file] [--sha sha] [--run-id id]" >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
RUN_JSON="${OUTPUT_DIR}/run.json"
FAILED_LOG="${OUTPUT_DIR}/failed.log"
OUT_JSON="${OUTPUT_DIR}/github-checks.json"

if ! command -v gh >/dev/null 2>&1; then
  jq -n \
    --arg repo "$REPO" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      source: "github",
      repo: $repo,
      generatedAt: $ts,
      checks: [
        {
          check: "github-api",
          status: "fail",
          exitCode: 1,
          summary: "gh CLI not available",
          logPath: null,
          source: "github",
          errors: ["gh command not found"]
        }
      ],
      errorSummary: ["gh command not found"]
    }' >"$OUT_JSON"
  echo "$OUT_JSON"
  exit 0
fi

if [[ -z "$RUN_ID" ]]; then
  if [[ -n "$WORKFLOW" && -n "$SHA" ]]; then
    RUN_ID="$(gh api -H 'Accept: application/vnd.github+json' "/repos/${REPO}/actions/workflows/${WORKFLOW}/runs?per_page=50" --jq ".workflow_runs[] | select(.head_sha==\"${SHA}\") | .id" 2>/dev/null | head -n 1 || true)"
  elif [[ -n "$SHA" ]]; then
    RUN_ID="$(gh api -H 'Accept: application/vnd.github+json' "/repos/${REPO}/actions/runs?per_page=50" --jq ".workflow_runs[] | select(.head_sha==\"${SHA}\") | .id" 2>/dev/null | head -n 1 || true)"
  fi
fi

if [[ -z "$RUN_ID" ]]; then
  jq -n \
    --arg repo "$REPO" \
    --arg workflow "$WORKFLOW" \
    --arg sha "$SHA" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      source: "github",
      repo: $repo,
      workflow: (if $workflow == "" then null else $workflow end),
      sha: (if $sha == "" then null else $sha end),
      generatedAt: $ts,
      checks: [
        {
          check: "github-run-lookup",
          status: "fail",
          exitCode: 1,
          summary: "Cannot resolve GitHub Actions run id",
          logPath: null,
          source: "github",
          errors: ["Run lookup failed"]
        }
      ],
      errorSummary: ["Run lookup failed"]
    }' >"$OUT_JSON"
  echo "$OUT_JSON"
  exit 0
fi

set +e
gh run view "$RUN_ID" --repo "$REPO" --json databaseId,status,conclusion,url,workflowName,headSha,jobs >"$RUN_JSON"
view_rc=$?
gh run view "$RUN_ID" --repo "$REPO" --log-failed >"$FAILED_LOG"
log_rc=$?
set -e

if [[ "$view_rc" -ne 0 ]]; then
  jq -n \
    --arg repo "$REPO" \
    --arg run_id "$RUN_ID" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      source: "github",
      repo: $repo,
      runId: ($run_id | tonumber?),
      generatedAt: $ts,
      checks: [
        {
          check: "github-run-view",
          status: "fail",
          exitCode: 1,
          summary: "gh run view failed",
          logPath: null,
          source: "github",
          errors: ["gh run view returned non-zero"]
        }
      ],
      errorSummary: ["gh run view returned non-zero"]
    }' >"$OUT_JSON"
  echo "$OUT_JSON"
  exit 0
fi

if [[ "$log_rc" -ne 0 ]]; then
  : >"$FAILED_LOG"
fi

ERRORS_JSON="$(
  { grep -Ein 'error|fail|exception|timeout|fatal' "$FAILED_LOG" 2>/dev/null || true; } \
    | head -n 80 \
    | cut -d: -f2- \
    | jq -R -s 'split("\n") | map(select(length>0))'
)"

jq \
  --arg repo "$REPO" \
  --arg workflow "$WORKFLOW" \
  --arg sha "$SHA" \
  --arg logPath "$FAILED_LOG" \
  --argjson errors "$ERRORS_JSON" \
  '
  . as $run
  | {
      source: "github",
      repo: $repo,
      workflow: (if $workflow == "" then (.workflowName // null) else $workflow end),
      sha: (if $sha == "" then (.headSha // null) else $sha end),
      runId: (.databaseId // null),
      status: (.status // null),
      conclusion: (.conclusion // null),
      url: (.url // null),
      checks: (
        [
          (.jobs // [])[]
          | select((.conclusion // .status // "") != "success" and (.conclusion // .status // "") != "skipped")
          | {
              check: ("github/" + ((.name // "unknown-job") | ascii_downcase | gsub("[^a-z0-9]+"; "-"))),
              status: "fail",
              exitCode: 1,
              summary: (
                "job="
                + (.name // "unknown")
                + "; failed_steps="
                + (
                    ((.steps // [])
                      | map(select((.conclusion // "") != "success" and (.conclusion // "") != "skipped") | .name)
                      | join(", "))
                  )
              ),
              logPath: $logPath,
              source: "github",
              errors: $errors
            }
        ]
      ),
      errorSummary: $errors
    }
  ' "$RUN_JSON" >"$OUT_JSON"

CHECKS_COUNT="$(jq '.checks | length' "$OUT_JSON")"
if [[ "$CHECKS_COUNT" -eq 0 ]]; then
  jq \
    --arg logPath "$FAILED_LOG" \
    --argjson errors "$ERRORS_JSON" \
    '
    .checks = [
      {
        check: "github/workflow",
        status: (if .conclusion == "success" then "pass" else "fail" end),
        exitCode: (if .conclusion == "success" then 0 else 1 end),
        summary: ("workflow conclusion=" + (.conclusion // "unknown")),
        logPath: $logPath,
        source: "github",
        errors: $errors
      }
    ]
    ' "$OUT_JSON" >"${OUT_JSON}.next"
  mv "${OUT_JSON}.next" "$OUT_JSON"
fi

echo "$OUT_JSON"
