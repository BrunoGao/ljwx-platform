#!/usr/bin/env bash
# gate-admin-route-coverage.sh — fail when admin page views are not wired into router
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ROUTER_FILE="ljwx-platform-admin/src/router/index.ts"
ALLOWLIST_FILE="scripts/gates/admin-route-allowlist.txt"

if [[ ! -f "$ROUTER_FILE" ]]; then
  echo "  gate-admin-route-coverage: SKIPPED (router file not found)"
  exit 0
fi

python3 - "$ROUTER_FILE" "$ALLOWLIST_FILE" <<'PY'
import pathlib
import re
import sys

router_file = pathlib.Path(sys.argv[1])
allowlist_file = pathlib.Path(sys.argv[2])
views_root = pathlib.Path("ljwx-platform-admin/src/views")

allowlist = set()
if allowlist_file.exists():
    for line in allowlist_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            allowlist.add(line)

router_text = router_file.read_text(encoding="utf-8")
routed = {
    match.replace("@/views/", "ljwx-platform-admin/src/views/")
    for match in re.findall(r"@/views/[^'\"`]+\.vue", router_text)
}

candidates = []
for file in sorted(views_root.rglob("*.vue")):
    rel = file.as_posix()
    if "/components/" in rel:
        continue
    if rel in allowlist:
        continue
    candidates.append(rel)

orphans = [path for path in candidates if path not in routed]

print(f"[Admin Route Coverage] routed={len(routed)} candidates={len(candidates)} orphans={len(orphans)}")

if orphans:
    for path in orphans:
        print(f"  FAIL: orphan admin page view — {path}")
    print("")
    print("════════════════════════════════════════════════════")
    print(f"  gate-admin-route-coverage: ERRORS={len(orphans)}")
    print("  gate-admin-route-coverage: FAILED")
    sys.exit(1)

print("")
print("════════════════════════════════════════════════════")
print("  gate-admin-route-coverage: ERRORS=0")
print("  gate-admin-route-coverage: PASSED")
PY

