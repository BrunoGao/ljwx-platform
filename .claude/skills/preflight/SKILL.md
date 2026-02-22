---
name: preflight
description: Run preflight self-check to verify all spec files, phase briefs, skills, and agents are properly set up before starting code generation. Use before Phase 0.
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Preflight 自检

在开始任何 Phase 之前执行完整的环境和文档自检。

## Step 1: 运行自动化脚本

```bash
bash scripts/preflight/preflight-check.sh
```

如果脚本返回非零退出码，逐项修复 FAIL 项后重新运行。

## Step 2: 语义一致性检查（脚本无法覆盖，需人工智能验证）

读取以下文件并检查：

### 2a. CLAUDE.md 硬规则 vs spec/01-constraints.md

读取两个文件，确认：
- CLAUDE.md 硬规则中提到的每条约束，在 spec/01-constraints.md 中有对应的详细定义
- 没有矛盾（例如 CLAUDE.md 说 "不使用 ROLE_ 前缀" 但 constraints 中写了 ROLE_）

### 2b. CLAUDE.md 版本表 vs spec/06-frontend-config.md 中的 package.json

读取两个文件，确认：
- spec/06-frontend-config.md 中所有 package.json 中的版本号与 CLAUDE.md 版本锁定表一致
- 所有依赖使用 `~` 而非 `^`

### 2c. Phase Brief 的读取清单 vs spec/ 文件实际章节

抽查 phase-00、phase-02、phase-05、phase-12 的"读取清单"：
- 列出的 spec 文件是否存在
- 列出的 §章节名是否能在对应文件中找到（模糊匹配即可）

### 2d. spec/03-api.md 路由表 vs spec/01-constraints.md 权限字符串

确认路由表中使用的所有权限字符串（如 user:read, job:execute）都在 RBAC 权限列表中。

## Step 3: 输出报告

输出格式：

```
============================
 PREFLIGHT REPORT
============================

## 自动化检查
[粘贴 preflight-check.sh 的输出]

## 语义一致性检查
| 检查项 | 结果 | 备注 |
|--------|------|------|
| 硬规则 vs constraints | ✅/❌ | ... |
| 版本号一致性 | ✅/❌ | ... |
| Phase Brief 引用有效性 | ✅/❌ | ... |
| 路由权限覆盖率 | ✅/❌ | ... |

## 结论
✅ READY — 可以开始 Phase 0
或
❌ NOT READY — 需要修复以下问题：[列表]
```
