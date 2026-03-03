# SSH 断线不影响 Codex/Claude 会话

目标：在远程 SSH 中断后，`codex` / `claude` 进程持续运行；重新 SSH 登录后直接回到原会话。

## 方案概览

- 会话承载：`tmux`
- 会话管理脚本：`scripts/tools/agent-session.sh`
- 自动回连脚本：`scripts/tools/install-ssh-autoreattach.sh`

## 一次性准备

```bash
# 1) 启动持久会话（首次会自动创建，后续自动恢复）
bash scripts/tools/agent-session.sh start codex

# 或者用 claude
bash scripts/tools/agent-session.sh start claude ljwx-agent-claude
```

## 日常使用

```bash
# 查看当前会话
bash scripts/tools/agent-session.sh status

# 回连会话（默认 ljwx-agent-codex）
bash scripts/tools/agent-session.sh attach

# 回连指定会话
bash scripts/tools/agent-session.sh attach ljwx-agent-claude

# 停止会话
bash scripts/tools/agent-session.sh stop ljwx-agent-codex
```

## 开启 SSH 登录自动回连（推荐）

默认写入 `~/.zshrc`：

```bash
bash scripts/tools/install-ssh-autoreattach.sh
```

也可指定写入其他 shell 配置文件：

```bash
bash scripts/tools/install-ssh-autoreattach.sh ~/.bashrc
```

安装后行为：
- 你通过 SSH 登录且不在 tmux 内时，会优先 `attach` 到 `ljwx-agent-codex`
- 若该会话不存在，会自动创建并启动 `codex`

## 可选增强（降低断线概率）

在 MacBook 客户端 `~/.ssh/config` 增加：

```sshconfig
Host your-server
  HostName <server-ip-or-domain>
  User <your-user>
  ServerAliveInterval 30
  ServerAliveCountMax 6
  TCPKeepAlive yes
```

以上配置是“降低断线概率”；真正保证断线后会话不断的是 `tmux`。
