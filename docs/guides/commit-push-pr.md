# Commit-Push-PR 工具使用指南

## 快速开始

### 基本用法

```bash
# 完整命令
bash scripts/commit-push-pr.sh -m "fix: Phase 54-58 评审问题修复"

# 快捷命令
bash scripts/cpp.sh "fix: Phase 54-58 评审问题修复"
```

## 命令选项

### 必填参数

- `-m, --message <msg>` - Commit 消息

### 可选参数

- `-t, --title <title>` - PR 标题（默认使用 commit 消息）
- `-b, --body <body>` - PR 描述
- `-B, --base <branch>` - 目标分支（默认 master）
- `--draft` - 创建草稿 PR
- `--no-pr` - 只 commit 和 push，不创建 PR
- `--dry-run` - 预览操作，不实际执行

## 使用示例

### 1. 基本提交并创建 PR

```bash
bash scripts/cpp.sh "fix: Phase 54-58 评审问题修复"
```

### 2. 创建草稿 PR

```bash
bash scripts/commit-push-pr.sh \
  -m "feat: 新增报表引擎" \
  -t "Phase 55: 报表引擎实现" \
  --draft
```

### 3. 自定义 PR 标题和描述

```bash
bash scripts/commit-push-pr.sh \
  -m "fix: 修复 XSS 漏洞" \
  -t "安全修复：Phase 58 XSS 防护" \
  -b "修复了帮助中心 Markdown 渲染的 XSS 漏洞，添加 DOMPurify 清洗"
```

### 4. 只提交和推送，不创建 PR

```bash
bash scripts/cpp.sh "chore: 更新文档" --no-pr
```

### 5. 预览操作（不实际执行）

```bash
bash scripts/commit-push-pr.sh -m "test commit" --dry-run
```

### 6. 指定目标分支

```bash
bash scripts/commit-push-pr.sh \
  -m "hotfix: 紧急修复" \
  -B develop
```

## 工作流程

脚本会按以下顺序执行：

1. **检查工作区** - 确认有未提交的更改
2. **显示文件列表** - 列出将要提交的文件
3. **Commit** - 执行 `git add -A` 和 `git commit`
4. **Push** - 推送到远程分支
5. **Create PR** - 使用 GitHub CLI 创建 PR（可选）

## 前置要求

### 必需

- Git 已配置
- 有未提交的更改

### 创建 PR 需要

- 安装 [GitHub CLI](https://cli.github.com/)
- 已登录 GitHub CLI (`gh auth login`)

如果未安装 GitHub CLI，可以使用 `--no-pr` 跳过 PR 创建。

## 错误处理

### 没有更改

```bash
$ bash scripts/cpp.sh "test"
[WARN] No changes to commit
```

### 未安装 GitHub CLI

```bash
[ERROR] GitHub CLI (gh) is not installed
[INFO] Install it from: https://cli.github.com/
[INFO] Or skip PR creation with --no-pr flag
```

### PR 已存在

```bash
[WARN] PR already exists for branch feature-branch: #123
[INFO] View PR: gh pr view 123 --web
```

## 最佳实践

1. **使用语义化提交消息**
   ```bash
   bash scripts/cpp.sh "feat: 新增功能"
   bash scripts/cpp.sh "fix: 修复 bug"
   bash scripts/cpp.sh "docs: 更新文档"
   bash scripts/cpp.sh "chore: 日常维护"
   ```

2. **草稿 PR 用于 WIP**
   ```bash
   bash scripts/cpp.sh "wip: 进行中的工作" --draft
   ```

3. **预览后再执行**
   ```bash
   bash scripts/cpp.sh "重要更改" --dry-run
   # 确认无误后
   bash scripts/cpp.sh "重要更改"
   ```

4. **分步操作**
   ```bash
   # 先提交推送
   bash scripts/cpp.sh "完成功能开发" --no-pr
   # 测试通过后再创建 PR
   gh pr create --base master --title "新功能"
   ```

## 快捷别名

可以在 `~/.bashrc` 或 `~/.zshrc` 中添加别名：

```bash
alias cpp='bash scripts/cpp.sh'
alias cppr='bash scripts/commit-push-pr.sh'
```

然后就可以直接使用：

```bash
cpp "fix: 修复问题"
cppr -m "feat: 新功能" --draft
```
