---
phase: 19
title: "Final Gate and Docs"
targets:
  backend: false
  frontend: false
depends_on: [18]
bundle_with: []
scope:
  - "FULL_MANIFEST.txt"
  - "docs/adr/**"
  - "README.md"
---
# Phase 19: Final Gate & Docs

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/` 目录全部文件（本 Phase 例外，允许全量扫描）
- `spec/08-output-rules.md`

## 任务

1. 执行 gate-all.sh 全量校验
2. 生成 FULL_MANIFEST.txt（仓库所有文件的完整列表）
3. 编写 ADR 文档
4. 编写 README.md
5. 最终版本验证

## Phase-Local Manifest

```
FULL_MANIFEST.txt
docs/adr/001-module-dependency-dag.md
docs/adr/002-audit-field-interceptor.md
docs/adr/003-jwt-authorities-convention.md
docs/adr/004-frontend-semver-tilde-only.md
docs/adr/005-changelog.md
README.md
```

## 验收条件

1. `bash scripts/gates/gate-all.sh` 全部通过
2. FULL_MANIFEST.txt 包含仓库所有文件
3. gate-manifest.sh FULL 模式校验通过
4. 至少 4 个 ADR 文档
5. README.md 包含项目简介、快速启动、技术栈、目录结构
6. 所有硬规则均满足（可使用 code-reviewer subagent 验证）

## 版本验证命令

```bash
java -version                                          # 含 21.0.10
./mvnw dependency:tree | grep spring-boot              # 3.5.11
./mvnw dependency:tree | grep mybatis                  # 3.0.5
./mvnw dependency:tree | grep springdoc                # 2.8.15
docker run --rm postgres:16.12-alpine postgres --version  # 16.12
node -v                                                # v22.22.0
pnpm -v                                                # 10.30.1
pnpm list vue --filter ljwx-platform-admin             # 3.5.28
pnpm list vite --filter ljwx-platform-admin            # 7.3.x
```
