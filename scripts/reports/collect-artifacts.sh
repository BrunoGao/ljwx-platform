#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE="${1:-00}"
if ! [[ "$PHASE" =~ ^[0-9]{2}$ ]]; then
  PHASE="00"
fi

RUN_ID="${GITHUB_RUN_ID:-local}"
BASE_DIR="docs/reports/data/artifacts/${RUN_ID}/phase-${PHASE}"
SUREFIRE_DIR="${BASE_DIR}/surefire"
FAILSAFE_DIR="${BASE_DIR}/failsafe"
mkdir -p "$SUREFIRE_DIR" "$FAILSAFE_DIR"

copy_report_dir() {
  local src="$1"
  local dst="$2"
  if [[ -d "$src" ]]; then
    find "$src" -maxdepth 1 -type f \( -name 'TEST-*.xml' -o -name '*.txt' -o -name '*.dump*' \) -exec cp {} "$dst"/ \; 2>/dev/null || true
  fi
}

copy_report_dir "ljwx-platform-app/target/surefire-reports" "$SUREFIRE_DIR"
copy_report_dir "ljwx-platform-app/target/failsafe-reports" "$FAILSAFE_DIR"

if [[ -f "gate.log" ]]; then
  cp "gate.log" "${BASE_DIR}/gate.log"
fi

python3 - "$PHASE" "$SUREFIRE_DIR" "${BASE_DIR}/surefire-index.json" "${BASE_DIR}/surefire-index.html" <<'PY'
import json
import pathlib
import re
import sys
import xml.etree.ElementTree as ET
from html import escape

phase = sys.argv[1]
report_dir = pathlib.Path(sys.argv[2])
json_out = pathlib.Path(sys.argv[3])
html_out = pathlib.Path(sys.argv[4])
phase_pattern = re.compile(rf"com\.ljwx\.platform\.phase{phase}\.")

items = []
for xml_path in sorted(report_dir.glob("TEST-*.xml")):
    try:
        root = ET.parse(xml_path).getroot()
    except Exception:
        continue
    suite = root.attrib.get("name", "")
    for case in root.findall("testcase"):
        classname = case.attrib.get("classname", "")
        if classname and not phase_pattern.search(classname):
            continue
        status = "PASS"
        message = ""
        details = ""
        node = case.find("failure")
        if node is not None:
            status = "FAIL"
            message = node.attrib.get("message", "") or "failure"
            details = (node.text or "").strip()
        else:
            node = case.find("error")
            if node is not None:
                status = "ERROR"
                message = node.attrib.get("message", "") or "error"
                details = (node.text or "").strip()
            else:
                node = case.find("skipped")
                if node is not None:
                    status = "SKIP"
                    message = node.attrib.get("message", "") or "skipped"
                    details = (node.text or "").strip()
        items.append(
            {
                "phase": phase,
                "suite": suite,
                "classname": classname,
                "testcase": case.attrib.get("name", ""),
                "status": status,
                "time_seconds": float(case.attrib.get("time", "0") or 0),
                "message": message,
                "details": details,
                "source_xml": xml_path.name,
            }
        )

summary = {
    "total": len(items),
    "pass": sum(1 for i in items if i["status"] == "PASS"),
    "fail": sum(1 for i in items if i["status"] in ("FAIL", "ERROR")),
    "skip": sum(1 for i in items if i["status"] == "SKIP"),
}

payload = {"phase": phase, "summary": summary, "tests": items}
json_out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

rows = []
for i in items:
    rows.append(
        "<tr>"
        f"<td>{escape(i['suite'] or i['classname'])}</td>"
        f"<td>{escape(i['testcase'])}</td>"
        f"<td>{escape(i['status'])}</td>"
        f"<td>{i['time_seconds']}</td>"
        f"<td>{escape(i['message'])}</td>"
        "</tr>"
    )
html = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Surefire Index Phase {phase}</title>
<style>body{{font-family:sans-serif;padding:16px}}table{{border-collapse:collapse;width:100%}}th,td{{border:1px solid #ddd;padding:6px;text-align:left}}</style>
</head><body>
<h2>Phase {phase} Surefire Index</h2>
<p>Total={summary['total']} Pass={summary['pass']} Fail={summary['fail']} Skip={summary['skip']}</p>
<table><thead><tr><th>Suite</th><th>Case</th><th>Status</th><th>Time(s)</th><th>Message</th></tr></thead><tbody>
{''.join(rows)}
</tbody></table>
</body></html>"""
html_out.write_text(html, encoding="utf-8")
PY

echo "${BASE_DIR}"
