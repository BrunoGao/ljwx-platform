---
name: cpp
description: Commit, push, and create PR in one command. Use when user wants to commit changes and create a pull request.
argument-hint: "[commit message] [--draft] [--no-pr]"
disable-model-invocation: false
---

# Commit-Push-PR 一键执行

执行以下操作：

1. **检查工作区状态**
   - 使用 `git status --short` 查看未提交的更改
   - 如果没有更改，提示用户并退出

2. **显示更改摘要**
   - 列出修改的文件
   - 列出新增的文件
   - 询问用户确认

3. **解析参数**
   - 从 $ARGUMENTS 中提取 commit 消息
   - 检查是否有 `--draft` 标志（创建草稿 PR）
   - 检查是否有 `--no-pr` 标志（不创建 PR）
   - 检查是否有 `--dry-run` 标志（预览模式）

4. **执行 commit-push-pr 脚本**
   ```bash
   bash scripts/commit-push-pr.sh -m "$COMMIT_MESSAGE" $FLAGS
   ```

5. **报告结果**
   - 显示 commit SHA
   - 显示 push 结果
   - 如果创建了 PR，显示 PR 链接

## 使用示例

```
/cpp "fix: Phase 54-58 评审问题修复"
/cpp "feat: 新增功能" --draft
/cpp "chore: 更新文档" --no-pr
/cpp "test commit" --dry-run
```

## 注意事项

- 如果未安装 GitHub CLI，会跳过 PR 创建（除非使用 --no-pr）
- 如果当前分支已有 PR，会提示而不是创建新的
- 使用 --dry-run 可以预览操作而不实际执行
