# Phase 0-10 Spec 优化工作总结

## 已完成的工作

### Phase 0 — Project Skeleton ✅
- **Spec**: `/spec/phase/phase-00.md` — 紧凑契约式，配置文件契约表格化
- **Tests**: `/spec/tests/phase-00-skeleton.tests.yml` — 15个测试用例（11 P0, 3 P1, 1 P2）
- **关键改进**:
  - 配置文件契约表格化（pom.xml, package.json, docker-compose.yml）
  - 业务规则编号（BL-00-01 ~ BL-00-04）
  - 测试用例外置到 YAML
  - 元数据表增加"测试契约"字段

### Phase 1 — Core Module ✅
- **Spec**: `/spec/phase/phase-01.md` — 类契约表格化
- **Tests**: `/spec/tests/phase-01-core.tests.yml` — 15个测试用例（10 P0, 5 P1）
- **关键改进**:
  - Result/ErrorCode/BaseEntity 类契约表格化
  - 接口方法签名明确列出
  - 禁止字段明确（BaseEntity 7个审计字段不可重复声明）
  - 业务规则编号（BL-01-01 ~ BL-01-04）

### Phase 2 — Data Module ✅
- **Spec**: `/spec/phase/phase-02.md` — 拦截器契约表格化
- **Tests**: `/spec/tests/phase-02-data.tests.yml` — 11个测试用例（9 P0, 2 P1）
- **关键改进**:
  - 拦截器契约（AuditFieldInterceptor, TenantLineInterceptor）
  - DAG 依赖约束明确（data 不依赖 security）
  - 业务规则编号（BL-02-01 ~ BL-02-04）

### Phase 3 — Security Module ✅
- **Spec**: `/spec/phase/phase-03.md` — JWT 工具类契约表格化
- **Tests**: `/spec/tests/phase-03-security.tests.yml` — 12个测试用例（10 P0, 2 P1）
- **关键改进**:
  - JWT Claims 结构明确
  - SecurityContext Holder 实现契约
  - 业务规则编号（BL-03-01 ~ BL-03-04）
  - 禁止 ROLE_ 前缀明确

## 待完成的工作

### Phase 4 — Web Module
- 需要创建 spec 和 tests.yml
- 重点：GlobalExceptionHandler, ResponseAdvice 契约

### Phase 5 — App Skeleton
- 已有参考示例（phase-05.md, phase-05-app.tests.yml）
- 需要按新格式优化

### Phase 6 — AI Context Docs
- 文档类 Phase，测试用例较少
- 重点：CLAUDE.md, spec.md 完整性验证

### Phase 7 — Quartz Integration
- 需要创建 spec 和 tests.yml
- 重点：Quartz 表结构、per-tenant 调度

### Phase 8 — Dict and Config
- 需要创建 spec 和 tests.yml
- 重点：Caffeine 缓存、CRUD 契约

### Phase 9 — Logs Notice and File
- 需要创建 spec 和 tests.yml
- 重点：异步日志、脱敏规则、文件上传

### Phase 10 — Index and Contract
- 需要创建 spec 和 tests.yml
- 重点：索引策略、OpenAPI 导出

## 新格式特点总结

### 1. 紧凑契约式
- 去掉冗长描述，改为契约表格
- 数据库契约、API 契约、DTO/VO 契约、类契约全部表格化

### 2. 测试外置
- 详细测试用例放在 `spec/tests/phase-XX-*.tests.yml`
- Spec 中只保留测试用例摘要（6-10 个 P0 用例）

### 3. 业务规则编号
- 使用 BL-XX-YY 格式（XX=Phase编号，YY=序号）
- 每条规则格式：[条件] → [动作] → [结果/异常]

### 4. 禁止字段明确
- 在 DTO/VO 契约中明确列出禁止字段
- 例如：`tenantId`、`createdBy`、`deleted` 等

### 5. 元数据表增强
- 增加"测试契约"字段，指向 tests.yml 文件
- 增加"Feature"字段，关联功能编号

### 6. 测试用例结构
```yaml
phase: XX
module: "module-name"
ac_ref: "spec/phase/phase-XX.md"

tests:
  - id: TC-XX-YY
    priority: P0/P1/P2
    category: security/crud/business/validation
    ac: AC-XX
    bl_ref: BL-XX-YY
    scenario: "场景描述"
    request: {...}
    expect: {...}

ac_tc_map:
  AC-01: [TC-XX-01, TC-XX-02]

gate_r09:
  p0_required: true
  p1_coverage_target: 0.7
  test_class: "XxxTest"
```

## 测试用例覆盖要求

### P0 用例（必须覆盖）
1. **安全测试**：401（无 Token）、403（无权限）
2. **CRUD 核心流程**：create/list/detail/update/delete
3. **租户隔离**：租户 A 查不到租户 B 数据
4. **软删除**：deleted=TRUE 后查询不返回
5. **关键业务规则**：每个 BL-XX-YY 至少一个 P0 用例

### P1 用例（70% 覆盖目标）
1. **参数校验**：必填字段为 null → 400
2. **边界条件**：不存在的 ID → 404
3. **业务规则细节**：复杂业务逻辑的各个分支

### P2 用例（可选）
1. **性能测试**：大数据量、并发
2. **极端边界**：超长字符串、特殊字符

## 下一步行动

1. **完成 Phase 4-10 的 spec 和 tests.yml 创建**
2. **验证所有 spec 文件格式一致性**
3. **确保每个 Phase 至少 10-15 个测试用例**
4. **P0 用例覆盖所有 AC 和关键 BL**
5. **更新 PHASE_MANIFEST.txt 中的文件清单**

## 参考文件

- **模板**: `spec/templates/phase-template.md`
- **示例 Spec**: `spec/phase/phase-05.md`, `spec/phase/phase-20.md`
- **示例 Tests**: `spec/tests/phase-05-app.tests.yml`, `spec/tests/phase-20-menu.tests.yml`
