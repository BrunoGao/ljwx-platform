---
phase: 8
title: "Dict and Config"
targets:
  backend: true
  frontend: false
depends_on: [7]
bundle_with: [7]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V012__create_sys_dict_type.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V013__create_sys_dict_data.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V014__create_sys_config.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/DictController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/ConfigController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/DictAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/ConfigAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDictType.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDictData.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysConfig.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDictTypeMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDictDataMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysConfigMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysDictTypeMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/SysDictDataMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/SysConfigMapper.xml"
---
# Phase 8 — 字典与配置 (Dict and Config)

| 项目 | 值 |
|-----|---|
| Phase | 8 |
| 模块 | ljwx-platform-app |
| Feature | F-008 (字典配置管理) |
| 前置依赖 | Phase 7 (Quartz Integration) |
| 测试契约 | `spec/tests/phase-08-dict-config.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §缓存策略、§审计字段
- `spec/03-api.md` — §Dicts 路由、§Configs 路由
- `spec/04-database.md` — V012 ~ V014
- `spec/08-output-rules.md`

---

## 数据库契约

### V012__create_sys_dict_type.sql（字典类型表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK | 雪花 ID |
| dict_name | VARCHAR(100) | NOT NULL | 字典名称 |
| dict_type | VARCHAR(100) | NOT NULL, UNIQUE | 字典类型（唯一键） |
| status | SMALLINT | NOT NULL | 状态（0=停用, 1=启用） |
| remark | VARCHAR(500) | NULL | 备注 |
| **审计字段** | | | **7 列** |

### V013__create_sys_dict_data.sql（字典数据表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK | 雪花 ID |
| dict_type | VARCHAR(100) | NOT NULL | 字典类型（外键） |
| dict_label | VARCHAR(100) | NOT NULL | 字典标签 |
| dict_value | VARCHAR(100) | NOT NULL | 字典值 |
| dict_sort | INTEGER | NOT NULL | 排序 |
| status | SMALLINT | NOT NULL | 状态 |
| remark | VARCHAR(500) | NULL | 备注 |
| **审计字段** | | | **7 列** |

索引：`idx_dict_type` ON (dict_type)

### V014__create_sys_config.sql（系统配置表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK | 雪花 ID |
| config_name | VARCHAR(100) | NOT NULL | 配置名称 |
| config_key | VARCHAR(100) | NOT NULL, UNIQUE | 配置键（唯一键） |
| config_value | VARCHAR(500) | NOT NULL | 配置值 |
| config_type | SMALLINT | NOT NULL | 配置类型（0=系统, 1=业务） |
| remark | VARCHAR(500) | NULL | 备注 |
| **审计字段** | | | **7 列** |

---

## API 契约

### DictController

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/dicts/types | system:dict:list | 查询字典类型列表 |
| GET | /api/v1/dicts/types/{id} | system:dict:detail | 查询字典类型详情 |
| POST | /api/v1/dicts/types | system:dict:create | 创建字典类型 |
| PUT | /api/v1/dicts/types/{id} | system:dict:update | 更新字典类型 |
| DELETE | /api/v1/dicts/types/{id} | system:dict:delete | 删除字典类型 |
| GET | /api/v1/dicts/data/{dictType} | system:dict:list | 根据类型查询字典数据 |
| POST | /api/v1/dicts/data | system:dict:create | 创建字典数据 |
| PUT | /api/v1/dicts/data/{id} | system:dict:update | 更新字典数据 |
| DELETE | /api/v1/dicts/data/{id} | system:dict:delete | 删除字典数据 |

### ConfigController

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/configs | system:config:list | 查询配置列表 |
| GET | /api/v1/configs/{id} | system:config:detail | 查询配置详情 |
| GET | /api/v1/configs/key/{configKey} | system:config:detail | 根据 key 查询配置 |
| POST | /api/v1/configs | system:config:create | 创建配置 |
| PUT | /api/v1/configs/{id} | system:config:update | 更新配置 |
| DELETE | /api/v1/configs/{id} | system:config:delete | 删除配置 |
| POST | /api/v1/configs/refresh | system:config:refresh | 刷新缓存 |

---

## DTO / VO 契约

### DictTypeCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| dictName | String | @NotBlank, @Size(max=100) | 字典名称 |
| dictType | String | @NotBlank, @Size(max=100), @Pattern | 字典类型（字母数字下划线） |
| status | Integer | @NotNull | 状态 |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`, `tenantId`, `createdBy`, `createdTime`, `updatedBy`, `updatedTime`, `deleted`, `version`

### ConfigCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| configName | String | @NotBlank, @Size(max=100) | 配置名称 |
| configKey | String | @NotBlank, @Size(max=100), @Pattern | 配置键（字母数字点下划线） |
| configValue | String | @NotBlank, @Size(max=500) | 配置值 |
| configType | Integer | @NotNull | 配置类型 |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`, `tenantId`, `createdBy`, `createdTime`, `updatedBy`, `updatedTime`, `deleted`, `version`

---

## 业务规则

- **BL-08-01**：字典和配置使用 Caffeine 缓存，TTL = 10 分钟
- **BL-08-02**：DictAppService 和 ConfigAppService 使用 `@Cacheable` / `@CacheEvict` 注解
- **BL-08-03**：dictType 和 configKey 必须唯一（数据库 UNIQUE 约束）
- **BL-08-04**：删除字典类型时，级联删除该类型下的所有字典数据
- **BL-08-05**：系统配置（configType=0）不允许删除，仅允许更新
- **BL-08-06**：刷新缓存接口清空所有字典和配置缓存

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-08-dict-config.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-08-01 | 无 Token → 401 | P0 |
| TC-08-02 | 无权限 → 403 | P0 |
| TC-08-03 | 创建字典类型成功 | P0 |
| TC-08-04 | 创建配置成功 | P0 |
| TC-08-05 | 租户隔离验证 | P0 |
| TC-08-06 | 缓存生效验证 | P0 |
| TC-08-07 | 刷新缓存成功 | P0 |
| TC-08-08 | 重复 dictType → 400 | P0 |

---

## 验收条件

- **AC-01**：V012-V014 包含 7 列审计字段，无 IF NOT EXISTS
- **AC-02**：DictAppService 和 ConfigAppService 使用 `@Cacheable` / `@CacheEvict`
- **AC-03**：Controller 所有方法有 @PreAuthorize
- **AC-04**：dictType 和 configKey 有 UNIQUE 约束
- **AC-05**：缓存 TTL = 10 分钟
- **AC-06**：`./mvnw compile -pl ljwx-platform-app` 通过

---

## 关键约束

- 禁止：IF NOT EXISTS · 缓存 TTL 不一致 · 系统配置允许删除
- Caffeine 缓存由 Spring Boot 管理，不使用 Redis
- dictType 和 configKey 必须唯一

## 可 Bundle

可与 Phase 7 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-08-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-08-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-08-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-08-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-08-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-08-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-08-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-08-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-08-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-08-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
