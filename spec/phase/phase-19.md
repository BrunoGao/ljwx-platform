---
phase: 19
title: "Interim Gate and Docs (阶段性验收与文档)"
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
# Phase 19 — 阶段性验收与文档 (Interim Gate & Docs)

> **注意**：本 Phase 是 Phase 0–18 的**阶段性**验收检查点，并非项目终态。后续仍有 Phase 20–32 功能阶段。真正的最终验收在 Phase 32。

| 项目 | 值 |
|-----|---|
| Phase | 19 |
| 模块 | 全仓库（Phase 0–18 范围） |
| Feature | F-019 (阶段性验收、文档) |
| 前置依赖 | Phase 18 (Screen Components) |
| 测试契约 | `spec/tests/phase-19-final.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/` 目录全部文件（本 Phase 例外，允许全量扫描）
- `spec/08-output-rules.md`

---

## 任务清单

### 1. 执行全量 Gate 校验

```bash
bash scripts/gates/gate-all.sh
```

### 2. 生成 FULL_MANIFEST.txt

```bash
find . -type f \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/dist/*" \
  -not -path "*/target/*" \
  > FULL_MANIFEST.txt
```

### 3. 编写 ADR 文档

至少 4 个 ADR：

- `docs/adr/001-module-dependency-dag.md` — 模块依赖 DAG 设计
- `docs/adr/002-audit-field-interceptor.md` — 审计字段拦截器设计
- `docs/adr/003-jwt-authorities-convention.md` — JWT 权限字符串约定
- `docs/adr/004-frontend-semver-tilde-only.md` — 前端版本号 ~ 策略
- `docs/adr/005-changelog.md` — 变更日志

### 4. 编写 README.md

包含：

- 项目简介
- 技术栈
- 快速启动
- 目录结构
- 开发规范
- 部署说明

### 5. 版本验证命令

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

---

## 验收条件

- **AC-01**：`bash scripts/gates/gate-all.sh` 全部通过
- **AC-02**：FULL_MANIFEST.txt 包含仓库所有文件
- **AC-03**：gate-manifest.sh FULL 模式校验通过
- **AC-04**：至少 4 个 ADR 文档
- **AC-05**：README.md 包含项目简介、快速启动、技术栈、目录结构
- **AC-06**：所有硬规则均满足

---

## 关键约束

- 必须：全量 Gate 通过 · FULL_MANIFEST.txt · ≥4 个 ADR · README.md
- 验证：所有版本号与 CLAUDE.md 版本锁定表一致

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
