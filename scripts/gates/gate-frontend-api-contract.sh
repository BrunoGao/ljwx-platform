#!/usr/bin/env bash
# gate-frontend-api-contract.sh — ensure admin/screen/mobile API clients only call exported OpenAPI paths
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

OPENAPI_FILE="${OPENAPI_FILE:-target/openapi.json}"
ALLOWLIST_FILE="scripts/gates/frontend-api-allowlist.txt"

if [[ ! -f "$OPENAPI_FILE" || ! -s "$OPENAPI_FILE" ]]; then
  OPENAPI_FILE="docs/api/openapi.json"
fi

if [[ ! -f "$OPENAPI_FILE" || ! -s "$OPENAPI_FILE" ]]; then
  echo "  FAIL: OpenAPI file not found. Run gate-contract first." >&2
  exit 1
fi

echo "[Frontend API Contract] Using $OPENAPI_FILE"

python3 - "$OPENAPI_FILE" "$ALLOWLIST_FILE" <<'PY'
import json
import pathlib
import re
import sys

openapi_file = pathlib.Path(sys.argv[1])
allowlist_file = pathlib.Path(sys.argv[2])

with open(openapi_file, "r", encoding="utf-8") as fh:
    spec = json.load(fh)

openapi_methods = {}
for path, methods in spec.get("paths", {}).items():
    canonical = re.sub(r"\{[^}]+\}", "{param}", path)
    openapi_methods.setdefault(canonical, set()).update(m.lower() for m in methods.keys())

allowlist = set()
if allowlist_file.exists():
    for line in allowlist_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            allowlist.add(line)

roots = [
    pathlib.Path("ljwx-platform-admin/src/api"),
    pathlib.Path("ljwx-platform-screen/src/api"),
    pathlib.Path("ljwx-platform-mobile/src/api"),
]

call_re = re.compile(
    r"request\.(get|post|put|delete|patch)(?:<[^>]+>)?\(\s*(?:`([^`]+)`|'([^']+)'|\"([^\"]+)\")"
)

errors = []
for root in roots:
    if not root.exists():
        continue
    for file in sorted(root.rglob("*.ts")):
        for lineno, line in enumerate(file.read_text(encoding="utf-8").splitlines(), start=1):
            for match in call_re.finditer(line):
                method = match.group(1).lower()
                path = next(group for group in match.groups()[1:] if group is not None)
                if not path.startswith("/api/"):
                    continue
                canonical = re.sub(r"\$\{[^}]+\}", "{param}", path)
                allow_key = f"{method} {canonical}"
                if allow_key in allowlist or canonical in allowlist:
                    continue
                supported = openapi_methods.get(canonical)
                if supported is None:
                    errors.append(f"{file}:{lineno} {method.upper()} {path} — path not found in OpenAPI")
                elif method not in supported:
                    errors.append(
                        f"{file}:{lineno} {method.upper()} {path} — path exists but method not exported ({sorted(supported)})"
                    )

if errors:
    for issue in errors:
        print(f"  FAIL: {issue}")
    print("")
    print("════════════════════════════════════════════════════")
    print(f"  gate-frontend-api-contract: ERRORS={len(errors)}")
    print("  gate-frontend-api-contract: FAILED")
    sys.exit(1)

print("")
print("════════════════════════════════════════════════════")
print("  gate-frontend-api-contract: ERRORS=0")
print("  gate-frontend-api-contract: PASSED")
PY
