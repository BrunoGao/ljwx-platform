#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

OUT="docs/reports/data/tests.json"
mkdir -p "$(dirname "$OUT")"

python3 - <<'PY'
import os
import json
import pathlib
import re
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

phase_map: dict[str, int] = {}
phase_map_file = pathlib.Path("spec/phase/logical-phase-map.json")
if phase_map_file.exists():
    try:
        raw = json.loads(phase_map_file.read_text(encoding="utf-8"))
        phase_map = {str(k): int(v) for k, v in raw.get("physical_to_logical", {}).items()}
    except Exception:
        phase_map = {}


def resolve_logical_phase(phase: str | None) -> str | None:
    if phase is None:
        return None
    mapped = phase_map.get(phase)
    if mapped is not None:
        return f"{mapped:02d}"
    p = int(phase)
    if 1 <= p <= 35:
        return f"{p:02d}"
    return None


tests = []
for report in sorted(pathlib.Path(".").glob("**/target/surefire-reports/TEST-*.xml")):
    try:
        root = ET.parse(report).getroot()
    except Exception:
        continue
    for case in root.findall("testcase"):
        classname = case.attrib.get("classname", "")
        name = case.attrib.get("name", "")
        t = case.attrib.get("time", "0")
        status = "PASS"
        message = ""
        failure = case.find("failure")
        error = case.find("error")
        skipped = case.find("skipped")
        if failure is not None:
            status = "FAIL"
            message = failure.attrib.get("message", "") or (failure.text or "").strip()
        elif error is not None:
            status = "ERROR"
            message = error.attrib.get("message", "") or (error.text or "").strip()
        elif skipped is not None:
            status = "SKIP"
            message = skipped.attrib.get("message", "") or (skipped.text or "").strip()

        phase = None
        m = re.search(r"com\.ljwx\.platform\.phase(\d{2})\.", classname)
        if m:
            phase = m.group(1)
        logical_phase = resolve_logical_phase(phase)
        try:
            time_seconds = float(t)
        except ValueError:
            time_seconds = 0.0

        tests.append({
            "phase": phase,
            "logical_phase": logical_phase,
            "suite": classname,
            "testcase": name,
            "status": status,
            "time_seconds": time_seconds,
            "message": message
        })

summary = {
    "total": len(tests),
    "pass": sum(1 for x in tests if x["status"] == "PASS"),
    "fail": sum(1 for x in tests if x["status"] in ("FAIL", "ERROR")),
    "skip": sum(1 for x in tests if x["status"] == "SKIP"),
}

out = {
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "ci": {
        "run_id": int(os.getenv("GITHUB_RUN_ID")) if os.getenv("GITHUB_RUN_ID", "").isdigit() else None,
        "run_attempt": int(os.getenv("GITHUB_RUN_ATTEMPT", "1") or 1),
        "workflow": os.getenv("GITHUB_WORKFLOW", "gate-local"),
        "run_url": os.getenv("GITHUB_SERVER_URL", "https://github.com")
        + "/"
        + os.getenv("GITHUB_REPOSITORY", "")
        + "/actions/runs/"
        + os.getenv("GITHUB_RUN_ID", "")
        if os.getenv("GITHUB_RUN_ID")
        else None,
    },
    "summary": summary,
    "tests": tests,
}
pathlib.Path("docs/reports/data/tests.json").write_text(
    json.dumps(out, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8"
)
print("docs/reports/data/tests.json")
PY
