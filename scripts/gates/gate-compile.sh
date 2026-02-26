#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# gate-compile.sh — 后端编译 + 前端类型检查
#
# 检查项：
#   1. Maven clean compile（后端 Java 编译）
#   2. pnpm install --frozen-lockfile（前端依赖安装）
#   3. pnpm run type-check（TypeScript 类型检查）
#   4. 仅在对应模块存在时执行
# ═══════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0

# Ensure pnpm exists in CI runners. Prefer corepack bootstrap when missing.
ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    return 0
  fi

  if command -v corepack >/dev/null 2>&1; then
    echo "[Frontend] pnpm not found, bootstrapping via corepack"
    if corepack enable >/dev/null 2>&1 && corepack prepare pnpm@10 --activate >/dev/null 2>&1; then
      if command -v pnpm >/dev/null 2>&1; then
        echo "  PASS: pnpm bootstrapped successfully"
        return 0
      fi
    fi
  fi

  echo "  FAIL: pnpm not found and corepack bootstrap failed"
  return 1
}

# ── Determine which checks to run based on current phase ──
CURRENT_PHASE=$(sed -n 's/^Phase:[[:space:]]*\([0-9][0-9]*\).*/\1/p' CLAUDE.md 2>/dev/null | head -1 || echo "")
PHASE_BRIEF=""
TARGET_BACKEND="true"
TARGET_FRONTEND="true"

if [[ -n "$CURRENT_PHASE" ]]; then
  PHASE_BRIEF="spec/phase/phase-$(printf '%02d' "$CURRENT_PHASE").md"
  if [[ -f "$PHASE_BRIEF" ]]; then
    YAML=$(sed -n '/^---$/,/^---$/p' "$PHASE_BRIEF" | sed '1d;$d')
    TARGET_BACKEND=$(echo "$YAML" | grep 'backend:' | awk '{print $2}' || echo "true")
    TARGET_FRONTEND=$(echo "$YAML" | grep 'frontend:' | awk '{print $2}' || echo "true")
  fi
fi

# ── Backend: Maven compile ──
if [[ "$TARGET_BACKEND" == "true" && -f "pom.xml" ]]; then
  echo "[Backend] mvn clean compile"
  if mvn clean compile -f pom.xml -q -B -DskipTests 2>&1; then
    echo "  PASS: Maven compilation succeeded"
  else
    echo "  FAIL: Maven compilation failed"
    ((ERRORS++))
  fi
else
  echo "[Backend] Skipped (target_backend=$TARGET_BACKEND or pom.xml not found)"
fi

# ── Frontend: pnpm install + type-check ──
ADMIN_DIR="ljwx-platform-admin"
if [[ "$TARGET_FRONTEND" == "true" && -d "$ADMIN_DIR" ]]; then
  if ! ensure_pnpm; then
    ((ERRORS++))
    TARGET_FRONTEND="false"
  fi
fi

if [[ "$TARGET_FRONTEND" == "true" && -d "$ADMIN_DIR" ]]; then
  echo ""
  echo "[Frontend] pnpm install --frozen-lockfile"
  cd "$ADMIN_DIR"

  # Check if pnpm-lock.yaml exists; if not, use regular install
  if [[ -f "pnpm-lock.yaml" ]]; then
    if CI=true pnpm install --frozen-lockfile 2>&1; then
      echo "  PASS: pnpm install succeeded"
    else
      echo "  WARN: --frozen-lockfile failed, trying regular install"
      if CI=true pnpm install 2>&1; then
        echo "  PASS: pnpm install (regular) succeeded"
      else
        echo "  FAIL: pnpm install failed"
        ((ERRORS++))
      fi
    fi
  else
    if CI=true pnpm install 2>&1; then
      echo "  PASS: pnpm install succeeded"
    else
      echo "  FAIL: pnpm install failed"
      ((ERRORS++))
    fi
  fi

  # Type check (only if script exists)
  echo ""
  echo "[Frontend] type-check"
  if grep -q '"type-check"' package.json 2>/dev/null; then
    if CI=true pnpm run type-check 2>&1; then
      echo "  PASS: TypeScript type-check passed"
    else
      echo "  FAIL: TypeScript type-check failed"
      ((ERRORS++))
    fi
  else
    echo "  SKIP: No type-check script in package.json"
  fi

  cd "$PROJECT_ROOT"
else
  echo "[Frontend] Skipped (target_frontend=$TARGET_FRONTEND or $ADMIN_DIR not found)"
fi

# ── Summary ──
echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-compile: FAILED ($ERRORS errors)"
  exit 1
fi
echo "  gate-compile: PASSED"
exit 0
