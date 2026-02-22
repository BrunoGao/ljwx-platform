---
name: gate-check
description: Run constraint checks on current phase output to verify LJWX platform rules
disable-model-invocation: true
argument-hint: [optional: phase-number]
---

# Gate 检查

对当前 Phase 的产出执行约束检查：

## 检查项

1. **Caret 检查**: 所有 `package.json` 中是否有 `^`（应全部为 `~`）
2. **Env 变量检查**: 是否存在 `VITE_API_BASE_URL`（应为 `VITE_APP_BASE_API`）
3. **审计字段检查**: Flyway SQL 中的 CREATE TABLE 是否包含 7 列审计字段（Quartz 除外）
4. **DAG 检查**: data 模块是否 import 了 security 包，反之亦然
5. **DTO 检查**: DTO 类中是否出现 tenantId 字段
6. **权限注解检查**: Controller 方法是否都有 @PreAuthorize（login/refresh 除外）
7. **TypeScript 检查**: .ts / .vue 文件中是否有 `: any` 或 `as any`
8. **Flyway 检查**: SQL 中是否有 `IF NOT EXISTS`
9. **Vue Router 检查**: 是否使用了 v4 已废弃的 API

## 执行

```bash
bash scripts/gates/gate-manifest.sh PHASE_MANIFEST.txt
```

对每个不通过的检查项，给出具体文件路径和修复建议。
