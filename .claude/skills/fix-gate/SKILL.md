---
name: fix-gate
description: Fix all gate failures for a phase. Reads gate output, fixes each violation, re-runs gate until all checks pass. Use when gate-all.sh reports FAILs.
argument-hint: "[phase-number]"
---

# 修复 Gate 失败

修复 Phase $ARGUMENTS 的所有 gate 失败项。

## 步骤

1. 运行 gate 获取失败列表：
   ```bash
   bash scripts/gates/gate-all.sh $ARGUMENTS
   ```

2. 对每条 `FAIL` 输出，按以下流程处理：

   **[no-preauthorize]** — Controller 缺少 @PreAuthorize：
   - 读取对应的 Controller 文件
   - 在每个 @*Mapping 上方添加 `@PreAuthorize("hasAuthority('resource:action')")`
   - login/refresh 端点除外

   **[no-caret]** — package.json 使用了 `^`：
   - 将所有 `"^x.y.z"` 改为 `"~x.y.z"`

   **[dto-no-tenant-id]** — DTO 含 tenantId 字段：
   - 删除该字段；在 Service 层从 SecurityContext 提取

   **[no-any]** — TypeScript 使用了 `any`：
   - 替换为正确的类型定义；从 @ljwx/shared 导入共享类型

   **[no-if-not-exists]** — Flyway SQL 含 IF NOT EXISTS：
   - 删除 `IF NOT EXISTS` 关键词（Flyway 通过版本号保证幂等性）

   **[wrong-env-var]** — 错误的环境变量名：
   - 替换为 `VITE_APP_BASE_API`

   **[dag-violation]** — 模块 DAG 违规：
   - 检查 import 语句，移除跨层引用
   - 如需共享，将类移至 core 模块

   **[audit-columns]** — SQL 缺少审计字段：
   - 添加 7 列：tenant_id, created_by, created_time, updated_by, updated_time, deleted, version

3. 每修复一类问题后，重新运行对应的编译/类型检查：
   - Java 文件修改后：`mvn clean compile -f pom.xml -q`
   - TS/Vue 文件修改后：`pnpm run type-check`（在 ljwx-platform-admin/）

4. 所有问题修复后，重新运行完整 gate：
   ```bash
   bash scripts/gates/gate-all.sh $ARGUMENTS
   ```

5. 重复步骤 2-4，直到 gate 输出全部 `PASS`。
