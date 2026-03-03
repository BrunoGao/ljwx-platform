#!/usr/bin/env bash
set -euo pipefail

COLLECT=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --collect) COLLECT="$2"; shift 2 ;;
    --output)  OUTPUT="$2";  shift 2 ;;
    *) echo "[diagnose] Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$COLLECT" || -z "$OUTPUT" ]]; then
  echo "[diagnose] Usage: $0 --collect <collect.json> --output <diagnosis.json>" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUTPUT")"

python3 - "$COLLECT" "$OUTPUT" <<'PY'
import json
import os
import re
import sys
from datetime import datetime, timezone

collect_path, output_path = sys.argv[1:]

def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

mechanical_signals = {
    "eslint": [r"\beslint\b", r"\blint\b"],
    "prettier": [r"\bprettier\b"],
    "spotless": [r"\bspotless\b"],
    "gofmt": [r"\bgofmt\b", r"\bgo fmt\b"],
    "black": [r"\bblack\b"],
    "isort": [r"\bisort\b"],
    "markdownlint": [r"\bmarkdown[- ]?lint\b"],
    "lockfile": [r"lockfile", r"pnpm-lock\.yaml", r"package-lock\.json", r"yarn\.lock"],
    "codegen": [r"openapi", r"codegen", r"generated file", r"missing generated"],
}

semi_signals = {
    "unit-test": [r"test(s)? failed", r"assert", r"surefire", r"failsafe", r"junit"],
    "contract": [r"\bcontract\b", r"\bschema\b", r"\bapi mismatch\b"],
    "flyway": [r"\bflyway\b", r"\bmigration\b", r"\bddl\b", r"\bchecksum\b"],
}

infra_signals = {
    "network-timeout": [r"timeout", r"timed out", r"connection reset", r"econnreset", r"dns", r"temporary failure"],
    "docker-pull": [r"docker pull", r"manifest unknown", r"image not found", r"buildx"],
    "test-flaky": [r"\bflaky\b", r"rerun", r"non-deterministic", r"intermittent"],
}

gate_rule_map = {
    "r03": "eslint",
    "r04": "flyway",
    "r06": "contract",
    "r09": "unit-test",
}

def text_blob(check):
    parts = [
        str(check.get("check") or ""),
        str(check.get("summary") or ""),
        " ".join(str(x) for x in (check.get("errors") or [])[:30]),
    ]
    return " ".join(parts).lower()

def match_signals(blob, signal_map):
    hit = []
    for key, pats in signal_map.items():
        for p in pats:
            if re.search(p, blob, re.IGNORECASE):
                hit.append(key)
                break
    return hit

def classify(check):
    blob = text_blob(check)
    for gate_id, signal in gate_rule_map.items():
        if re.search(rf"\b{re.escape(gate_id)}\b", blob):
            blob += f" {signal}"

    mech = match_signals(blob, mechanical_signals)
    semi = match_signals(blob, semi_signals)
    infra = match_signals(blob, infra_signals)

    if mech:
        category = "A"
        repairability = "auto"
        confidence = 0.95
        signals = mech
        reason = "Deterministic lint/format/codegen class failure."
    elif semi:
        if "unit-test" in semi and not any(s in {"contract", "flyway"} for s in semi):
            category = "C"
            repairability = "mitigate"
            confidence = 0.68
            signals = ["test-flaky"]
            reason = "Unit test failure first goes through flaky rerun mitigation."
        else:
            category = "B"
            repairability = "auto"
            confidence = 0.78 if any(s in {"contract", "flyway"} for s in semi) else 0.62
            signals = semi
            reason = "Semi-deterministic test/schema/migration class failure."
    elif infra:
        category = "C"
        repairability = "mitigate"
        confidence = 0.72
        signals = infra
        reason = "Infra/environmental instability; apply mitigation and retries."
    else:
        category = "D"
        repairability = "manual"
        confidence = 0.35
        signals = []
        reason = "Complex logic/spec mismatch likely needs human context."

    # Deduplicate while preserving order.
    seen = set()
    uniq_signals = []
    for s in signals:
        if s not in seen:
            seen.add(s)
            uniq_signals.append(s)

    return {
        "check": check.get("check"),
        "source": check.get("source"),
        "category": category,
        "repairability": repairability,
        "confidence": confidence,
        "reason": reason,
        "signals": uniq_signals,
        "recommendedRecipes": uniq_signals,
        "evidence": {
            "summary": check.get("summary"),
            "errors": (check.get("errors") or [])[:20],
            "logPath": check.get("logPath"),
        },
    }

payload = json.load(open(collect_path, "r", encoding="utf-8"))
failed = payload.get("failed") or []
diagnoses = [classify(c) for c in failed]

counts = {"A": 0, "B": 0, "C": 0, "D": 0}
repairability_counts = {"auto": 0, "suggest": 0, "mitigate": 0, "manual": 0}
for d in diagnoses:
    counts[d["category"]] = counts.get(d["category"], 0) + 1
    repairability_counts[d["repairability"]] = repairability_counts.get(d["repairability"], 0) + 1

out = {
    "phase": payload.get("phase"),
    "attempt": payload.get("attempt"),
    "generatedAt": utc_now(),
    "input": {"collect": collect_path},
    "summary": {
        "failedChecks": len(failed),
        "categoryCounts": counts,
        "repairabilityCounts": repairability_counts,
    },
    "diagnoses": diagnoses,
}

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(output_path)
PY
