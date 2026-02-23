# LJWX Platform — 关键决策记录

本文件记录已做出的架构决策，避免重复讨论。

## 2026-02-23: macOS 兼容性 — 使用 ERE 而非 PCRE

所有 shell 脚本使用 POSIX ERE（`grep -E`），禁止 `grep -P`（GNU/PCRE-only）。
理由：macOS 自带 BSD grep 不支持 `-P`。

具体替换规则：
- `\s` → `[[:space:]]`
- `\S` → `[^[:space:]]`
- `\|`（PCRE 交替） → `|`（ERE 交替）
- `\K`（lookbehind）→ `sed -n 's/.../\1/p'`
- `(?!...)`（负向前瞻）→ 两步 grep：先匹配，再排除

## 2026-02-23: Flyway 规范 — 禁止 IF NOT EXISTS

Flyway 通过版本号管理迁移，不需要幂等 DDL。
`CREATE TABLE IF NOT EXISTS` 是反模式，已通过 post-edit-check.sh hook 拦截。

## 2026-02-23: Vue Router v5 API

项目使用 vue-router `~5.0.2`。v5 将 unplugin-vue-router 功能内置。
所有代码必须用 Composition API（`useRoute()`/`useRouter()`），禁止 Options API 路由守卫。
`onBeforeRouteLeave` 和 `onBeforeRouteUpdate` 在 v5 中合法。

## 2026-02-23: Hook 机制

Claude Code hooks 仅支持三种事件：`PreToolUse`、`PostToolUse`、`Stop`。
`SessionStart` 不是有效事件类型。
PreToolUse → pre-edit-guard.sh（路径级阻断）
PostToolUse → post-edit-check.sh（内容级检查）
Stop → stop-gate.sh（Phase 完成校验）

## 2026-02-23: .env.example 处理

Claude Code 系统沙箱阻止写入所有 `.env.*` 文件（含 `.env.example`）。
解决方案：`stop-gate.sh` 跳过 `.env*` 文件的 scope 检查；用户手动创建该文件。

## 2026-02-23: settings.json 权限策略

使用 `"defaultMode": "dontAsk"` 配合精细化 allow/deny 列表。
`sandbox.enabled: true` 提供额外的系统级保护。
代理类型权限用 `Task(backend-builder)` 格式。
