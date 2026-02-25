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

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-19-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-19-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-19-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-19-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-19-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-19-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-19-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-19-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-19-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-19-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
