#!/usr/bin/env bash
# Export OpenAPI spec from a running application instance.
# Usage: bash scripts/tools/export-openapi.sh [base-url]

set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
OUTPUT_DIR="docs/contracts"
OUTPUT="${OUTPUT_DIR}/openapi.json"

mkdir -p "$OUTPUT_DIR"

echo "[export-openapi] Fetching spec from ${BASE_URL}/v3/api-docs"

for i in $(seq 1 10); do
  if curl -sf "${BASE_URL}/v3/api-docs" -o "$OUTPUT"; then
    echo "[export-openapi] Saved to ${OUTPUT}"
    exit 0
  fi
  echo "  Attempt $i failed, retrying in 2s..."
  sleep 2
done

echo "[export-openapi] FAIL: Could not fetch OpenAPI spec from ${BASE_URL}/v3/api-docs"
exit 1
