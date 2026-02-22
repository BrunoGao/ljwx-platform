# 输出规则

## Phase 输出格式

每个 Phase 的输出必须包含以下段落（按此顺序）：

```
PHASE {N}: {标题}

PHASE-LOCAL MANIFEST
（仅列出本阶段新增或修改的文件路径）

NEW FILES
（完整文件内容，不省略）

PATCHES
（对已有文件的 unified diff）

TESTS
（本阶段应通过的测试）

COMMANDS
（本阶段执行的验证命令）

ACCEPTANCE
（本阶段的验收条件）

RISKS & ROLLBACK
（风险点与回退方案）
```

## 强制规则

1. **不省略**: 每个 NEW FILES 段必须输出完整文件内容。禁止 `// ... 省略 ...` 或 `/* same as before */`
2. **Unified Diff**: 对已有文件的修改使用标准 `--- a/path` / `+++ b/path` 格式
3. **Phase-Local Manifest**: 每个 Phase 的 MANIFEST 仅列出本阶段的文件，不列未来 Phase 的文件
4. **PATCHES 最小化**: 仅修改与本 Phase 直接相关的文件。禁止顺手重构、重新格式化、批量重写无关文件

## Phase 19 Final Manifest

Phase 19 的 gate-manifest.sh 执行 FULL 模式：遍历仓库所有预期文件路径，确认每个文件存在且非空。此时生成 FULL_MANIFEST.txt，包含仓库内所有文件的完整列表。

## Bundle 执行规则

允许一次指令执行多个 Phase（Bundle），但每个 Phase 必须有独立的输出块。例如执行 Phase 2+3 时，输出中必须分别有 `## PHASE 2` 和 `## PHASE 3` 两个完整块，各含自己的 MANIFEST、NEW FILES、ACCEPTANCE 等。
