---
name: phase-exec
description: Execute a specific phase of LJWX platform development. Use when asked to implement a phase or when the user says phase followed by a number.
argument-hint: [phase-number or range like 0-1]
---

# Phase 执行流程

执行 Phase $ARGUMENTS：

1. 读取 `spec/phase/phase-$ARGUMENTS.md`
2. 按其中的"读取清单"加载所需 spec 文件（仅加载列出的文件和章节）
3. 按 `spec/08-output-rules.md` 的格式生成输出
4. 如果是 Bundle（如 $ARGUMENTS 是 "0-1" 或 "2+3"），分别读取对应的 phase brief，每个 Phase 输出独立的块
5. 输出前自检：
   - 所有 NEW FILES 是否完整（无省略标记）
   - CLAUDE.md 中的硬规则是否全部满足
   - Phase-Local Manifest 中的每个文件是否都已生成
   - import 路径是否符合 DAG 依赖规则
   - package.json 是否全部使用 ~ 而非 ^
6. 完成后提示用户更新 CLAUDE.md 中的 Current Phase
