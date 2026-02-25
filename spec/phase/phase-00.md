---
phase: 0
title: "Project Skeleton"
targets:
  backend: true
  frontend: true
depends_on: []
bundle_with: [1]
scope:
  - "pom.xml"
  - ".mvn/**"
  - "pnpm-workspace.yaml"
  - "package.json"
  - ".npmrc"
  - ".nvmrc"
  - "docker-compose.yml"
  - ".env.example"
  - ".gitignore"
  - ".editorconfig"
  - "scripts/gates/**"
  - "scripts/tools/**"
  - "scripts/acceptance/**"
  - "PHASE_MANIFEST.txt"
---
# Phase 0: Skeleton

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-architecture.md` — §仓库结构
- `spec/06-frontend-config.md` — §pnpm-workspace.yaml、§Root package.json、§.npmrc、§.nvmrc、§.env.example
- `spec/07-devops.md` — §Docker Compose、§CI Gate 脚本全部
- `spec/08-output-rules.md` — 全文

## 任务

创建项目骨架：所有配置文件和 CI 脚本。不包含任何 Java 源码或前端源码。

## Phase-Local Manifest

```
pom.xml
.mvn/wrapper/maven-wrapper.properties
pnpm-workspace.yaml
package.json
.npmrc
.nvmrc
docker-compose.yml
.env.example
.gitignore
.editorconfig
scripts/gates/gate-all.sh
scripts/gates/gate-compile.sh
scripts/gates/gate-integration.sh
scripts/gates/gate-contract.sh
scripts/gates/gate-manifest.sh
scripts/gates/gate-nfr.sh
scripts/tools/export-openapi.sh
scripts/acceptance/smoke-test.sh
PHASE_MANIFEST.txt
```

## 验收条件

1. `pom.xml` 中 Java source/target = 21，Spring Boot parent 版本来自 CLAUDE.md
2. `package.json` 的 `packageManager` 字段与 CLAUDE.md 一致
3. `.nvmrc` 内容与 CLAUDE.md 一致
4. `docker-compose.yml` 使用 `postgres:16.12-alpine`
5. 所有 `package.json` 中无 `^`
6. `.env.example` 使用 `VITE_APP_BASE_API`，无 `VITE_API_BASE_URL`
7. `gate-manifest.sh` 包含 7 列审计字段循环检查 + caret 全局扫描 + env 变量三端扫描

## 验证命令

```bash
grep -RIn '"\^' package.json || echo "OK: No caret in root"
grep -RIn 'VITE_API_BASE_URL' .env.example && echo "FAIL" || echo "OK"
```

## 可 Bundle

可与 Phase 1 一起执行，但必须分开两个 Phase 块输出。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-00-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-00-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-00-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-00-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-00-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-00-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-00-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-00-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-00-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-00-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
