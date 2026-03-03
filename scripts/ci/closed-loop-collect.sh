#!/usr/bin/env bash
set -euo pipefail

PHASE=""
ATTEMPT=""
CHECKS_DIR=""
GITHUB_FILE=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)       PHASE="$2"; shift 2 ;;
    --attempt)     ATTEMPT="$2"; shift 2 ;;
    --checks-dir)  CHECKS_DIR="$2"; shift 2 ;;
    --github-file) GITHUB_FILE="$2"; shift 2 ;;
    --output)      OUTPUT="$2"; shift 2 ;;
    *) echo "[collect] Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$OUTPUT" ]]; then
  echo "[collect] --output is required" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUTPUT")"

python3 - "$PHASE" "$ATTEMPT" "$CHECKS_DIR" "$GITHUB_FILE" "$OUTPUT" <<'PY'
import glob
import json
import os
import sys
from datetime import datetime, timezone

phase, attempt, checks_dir, github_file, output = sys.argv[1:]

def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def norm_status(raw):
    s = str(raw or "").strip().lower()
    if s in {"pass", "passed", "success", "ok"}:
        return "pass"
    if s in {"skip", "skipped"}:
        return "skip"
    if s in {"fail", "failed", "error"}:
        return "fail"
    return "unknown"

def to_int_or_none(v):
    if v is None:
        return None
    try:
        return int(v)
    except Exception:
        return None

def norm_check(item, default_source="local"):
    if not isinstance(item, dict):
        return None
    check = str(item.get("check") or item.get("name") or "unknown-check")
    status = norm_status(item.get("status"))
    exit_code = to_int_or_none(item.get("exitCode"))
    if status == "unknown":
        status = "fail" if (exit_code is not None and exit_code != 0) else "pass"
    summary = str(item.get("summary") or "")
    log_path = str(item.get("logPath") or item.get("log") or "")
    source = str(item.get("source") or default_source)
    errors = item.get("errors") or []
    if not isinstance(errors, list):
        errors = [str(errors)]
    errors = [str(e) for e in errors if str(e).strip()]
    return {
        "check": check,
        "status": status,
        "exitCode": exit_code,
        "summary": summary,
        "logPath": log_path,
        "source": source,
        "errors": errors,
    }

checks = []

if checks_dir:
    for path in sorted(glob.glob(os.path.join(checks_dir, "*.json"))):
        try:
            data = json.load(open(path, "r", encoding="utf-8"))
        except Exception:
            continue
        if isinstance(data, dict) and isinstance(data.get("checks"), list):
            for entry in data["checks"]:
                c = norm_check(entry, "local")
                if c:
                    checks.append(c)
        else:
            c = norm_check(data, "local")
            if c:
                checks.append(c)

if github_file:
    try:
        data = json.load(open(github_file, "r", encoding="utf-8"))
        if isinstance(data, dict) and isinstance(data.get("checks"), list):
            for entry in data["checks"]:
                c = norm_check(entry, "github")
                if c:
                    checks.append(c)
        else:
            c = norm_check(data, "github")
            if c:
                checks.append(c)
    except Exception:
        pass

failed = []
for c in checks:
    fail_by_status = c["status"] == "fail"
    fail_by_exit = c["exitCode"] is not None and c["exitCode"] != 0
    if fail_by_status or fail_by_exit:
        failed.append(c)

error_summary = []
for c in failed:
    if c["summary"]:
        error_summary.append(f"[{c['source']}:{c['check']}] {c['summary']}")
    for e in c["errors"][:5]:
        error_summary.append(f"[{c['source']}:{c['check']}] {e}")

payload = {
    "phase": phase or None,
    "attempt": int(attempt) if str(attempt).isdigit() else None,
    "generatedAt": utc_now(),
    "checks": checks,
    "failed": failed,
    "summary": {
        "totalChecks": len(checks),
        "failedChecks": len(failed),
    },
    "errorSummary": error_summary[:200],
}

with open(output, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(output)
PY
