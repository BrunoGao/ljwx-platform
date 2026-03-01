# Spec Registry (SSOT)

本目录包含 LJWX Platform 的**单一真相源 (Single Source of Truth)**。

所有 Phase spec 文档中的关键配置必须引用这里的 registry,不允许自行定义。

---

## Registry 文件

| 文件 | 说明 | 强制性 |
|------|------|--------|
| [permissions.yml](./permissions.yml) | 权限字符串注册表 | ✅ 强制 |
| [migrations.yml](./migrations.yml) | Flyway 版本号注册表 | ✅ 强制 |
| [observability.yml](./observability.yml) | 可观测性配置 (Loki/Prometheus label 白名单) | ✅ 强制 |
| [constraints.yml](./constraints.yml) | 全局硬约束 (Redis/MQ/缓存策略等) | ✅ 强制 |

---

## 使用规则

### 1. 权限字符串 (permissions.yml)

**Phase spec 中出现的权限必须在 permissions.yml 中注册。**

✅ 正确:
```yaml
# Phase spec
权限: system:user:list

# permissions.yml 中已注册
- code: "system:user:list"
  name: "用户列表"
```

❌ 错误:
```yaml
# Phase spec
权限: system:user:view  # permissions.yml 中不存在
```

### 2. Flyway 版本号 (migrations.yml)

**Phase spec 中的迁移版本号必须在 migrations.yml 中注册。**

✅ 正确:
```yaml
# Phase spec
Flyway: V033

# migrations.yml 中已注册
- version: "033"
  description: "create_cache_invalidation_event"
  phase: 33
```

❌ 错误:
```yaml
# Phase spec
Flyway: V034  # 与 Phase 34 冲突
```

### 3. 可观测性配置 (observability.yml)

**Phase spec 中的 Loki/Prometheus label 必须符合白名单。**

✅ 正确:
```yaml
# Phase spec
Loki labels: app, env, level

# observability.yml 白名单
labels_whitelist: ["app", "env", "level"]
```

❌ 错误:
```yaml
# Phase spec
Loki labels: app, env, level, tenantId  # tenantId 在黑名单中
```

### 4. 全局约束 (constraints.yml)

**Phase spec 中引入的基础设施必须符合 constraints.yml。**

✅ 正确:
```yaml
# Phase spec
引入 Redis 用于 L2 缓存

# constraints.yml 允许
infrastructure:
  cache:
    redis:
      allowed: true
```

❌ 错误:
```yaml
# Phase spec
引入 Kafka 用于消息队列

# constraints.yml 禁止
infrastructure:
  message_queue:
    allowed: false
```

---

## CI Gate 检查

以下检查会在 CI 中自动执行,违反规则会导致合并失败:

1. **权限校验**: Phase spec 中的权限必须在 permissions.yml 中注册
2. **Flyway 唯一性**: migrations.yml 中的版本号不允许重复
3. **引用存在性**: Phase spec 引用的文件必须存在
4. **可观测 label 白名单**: Loki/Prometheus label 必须符合白名单
5. **约束冲突检查**: Phase spec 引入的基础设施必须符合 constraints.yml

详见: `.github/workflows/spec-quality-gate.yml`

---

## 如何更新 Registry

### 新增权限

1. 在 `permissions.yml` 中添加权限定义
2. 提交 PR,通过 review 后合并
3. Phase spec 中引用新权限

### 新增 Flyway 版本

1. 在 `migrations.yml` 中预留版本号
2. 填写 description, type, phase, tables
3. 提交 PR,���过 review 后合并
4. Phase spec 中引用新版本号

### 修改约束

1. 在 `constraints.yml` 中修改约束
2. 补充 ADR 说明变更原因
3. 提交 PR,通过 review 后合并
4. Phase spec 中引用新约束

---

## 相关文档

- [ADR 索引](../../docs/adr/README.md)
- [Phase Spec 模板](../phase/TEMPLATE.md)
- [全局约束](../01-constraints.md)
- [P0-P1 Spec 索引](../../docs/P0-P1-Spec-Index.md)

---

**版本**: v1.0
**最后更新**: 2025-03-01
**维护者**: LJWX Platform Team
