# Phase {NN} — {功能名称} ({English Name})

| 项目 | 值 |
|-----|---|
| Phase | {NN} |
| 模块 | {Maven 模块名，如 ljwx-platform-app} |
| Feature | F-{NNN} (如有对应 Feature Brief) |
| 前置依赖 | Phase X, Phase Y |
| 预计文件数 | {数量，如 12-15} |

## 数据库设计

### 表结构

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| {业务字段} | {类型} | {约束} | {说明} |
| tenant_id | BIGINT | NOT NULL, INDEX | 租户 ID（框架自动填充） |
| created_by | BIGINT | NULLABLE | 创建人 |
| created_time | DATETIME | NOT NULL, DEFAULT NOW() | 创建时间 |
| updated_by | BIGINT | NULLABLE | 更新人 |
| updated_time | DATETIME | NOT NULL, DEFAULT NOW() ON UPDATE NOW() | 更新时间 |
| deleted | TINYINT | NOT NULL, DEFAULT 0 | 软删除标记 |
| version | INT | NOT NULL, DEFAULT 0 | 乐观锁版本号 |

### Flyway 文件

- 文件名: `V{NNN}__create_{table_name}.sql`
- 命名规则: Phase 编号对应 Flyway 版本号
- 必须包含: 表创建、索引创建、注释
- 禁止包含: `IF NOT EXISTS`、初始数据（初始数据用单独的 `V{NNN}_1__init_data.sql`）

## API 定义

### 端点列表

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/{resource} | {module}:{entity}:list | — | R<PageResult<{Entity}VO>> | 分页查询 |
| GET | /api/v1/{resource}/{id} | {module}:{entity}:read | — | R<{Entity}DetailVO> | 查询详情 |
| POST | /api/v1/{resource} | {module}:{entity}:create | {Entity}CreateDTO | R<Long> | 创建 |
| PUT | /api/v1/{resource}/{id} | {module}:{entity}:update | {Entity}UpdateDTO | R<Void> | 更新 |
| DELETE | /api/v1/{resource}/{id} | {module}:{entity}:delete | — | R<Void> | 删除 |

### 通用约定

- 所有端点前缀: `/api/v1/`
- 响应统一包装: `R<T>`（code, message, data, traceId）
- 认证: Bearer Token（Header: Authorization）
- 未认证: 401，无权限: 403，参数错误: 400，业务异常: 500 + 业务错误码

## 类设计

### Entity

```java
// com.ljwx.platform.{module}.entity.{Entity}
@Data
@TableName("{table_name}")
public class {Entity} extends BaseTenantEntity {
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    // 业务字段
    private String fieldName;

    // tenant_id, created_by, created_time, updated_by, updated_time, deleted, version
    // 由 BaseTenantEntity 和 MyBatis-Plus 自动填充，此处不声明
}
```

### DTO

```java
// {Entity}CreateDTO — 创建请求
// 字段: {列出所有字段及校验规则}
// 禁止包含: id, tenantId, createdBy, createdTime, updatedBy, updatedTime, deleted, version

// {Entity}UpdateDTO — 更新请求
// 字段: 同 CreateDTO，所有字段可选（Partial Update）
// 禁止包含: id, tenantId, createdBy, createdTime, updatedBy, updatedTime, deleted, version

// {Entity}QueryDTO — 查询条件
// 字段: {列出查询字段}
// 禁止包含: tenantId（由框架自动注入）
```

### VO

```java
// {Entity}VO — 列表响应
// 字段: id, {业务字段}, createdTime, updatedTime
// 禁止包含: tenantId, deleted, createdBy, updatedBy, version

// {Entity}DetailVO — 详情响应
// 字段: 同 VO，可包含更多详细信息
```

### Mapper

```java
// {Entity}Mapper extends BaseMapper<{Entity}>
// {Entity}Mapper.xml — 仅在需要自定义 SQL 时创建
```

### Service

```java
// I{Entity}Service extends IService<{Entity}>
// {Entity}ServiceImpl extends ServiceImpl<{Entity}Mapper, {Entity}> implements I{Entity}Service
```

## 业务逻辑

### 查询
1. 条件 → 动作 → 结果

### 创建
1. 条件 → 动作 → 结果

### 更新
1. 条件 → 动作 → 结果

### 删除
1. 条件 → 动作 → 结果

## 测试用例

### 安全测试（Security）

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-{NN}-01 | 未认证访问 | GET /api/v1/{resource} (无 Token) | 401 | P0 |
| TC-{NN}-02 | 无权限访问 | GET /api/v1/{resource} (无权限) | 403 | P0 |

### CRUD 测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-{NN}-03 | 正常查询列表 | GET /api/v1/{resource} | 200, 返回列表 | P0 |
| TC-{NN}-04 | 正常创建 | POST /api/v1/{resource} | 200, 返回 ID | P0 |
| TC-{NN}-05 | 正常更新 | PUT /api/v1/{resource}/{id} | 200 | P0 |
| TC-{NN}-06 | 正常删除 | DELETE /api/v1/{resource}/{id} | 200 | P0 |
| TC-{NN}-07 | 查询详情 | GET /api/v1/{resource}/{id} | 200, 字段完整 | P1 |

### 业务规则测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-{NN}-08 | 租户隔离 | 租户 A 查询，不返回租户 B 数据 | 仅返回本租户数据 | P0 |
| TC-{NN}-09 | 软删除验证 | 删除后数据库 deleted=1，API 查询不返回 | 符合预期 | P0 |

### 参数校验测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-{NN}-10 | 必填字段为空 | POST {field}=null | 400 | P1 |
| TC-{NN}-11 | 字段超长 | POST {field}=超长字符串 | 400 | P2 |

## 验收条件映射

| 验收条件 | 来源 | 测试用例 | Gate 维度 |
|---------|------|----------|----------|
| AC-01 | F-{NNN} | TC-{NN}-01 | R05 |
| AC-02 | F-{NNN} | TC-{NN}-02, TC-{NN}-03 | R04, R05 |

## 预期生成文件

| 文件路径 | 类型 | Gate 关联 |
|---------|------|----------|
| db/migration/V{NNN}__create_{table}.sql | Migration | R02 |
| .../entity/{Entity}.java | Entity | R07 |
| .../mapper/{Entity}Mapper.java | Mapper | R06 |
| .../mapper/xml/{Entity}Mapper.xml | Mapper XML | R05 |
| .../dto/{Entity}CreateDTO.java | DTO | R03 |
| .../dto/{Entity}UpdateDTO.java | DTO | R03 |
| .../dto/{Entity}QueryDTO.java | DTO | R03 |
| .../vo/{Entity}VO.java | VO | R03 |
| .../vo/{Entity}DetailVO.java | VO | R03 |
| .../service/I{Entity}Service.java | Service | R06 |
| .../service/impl/{Entity}ServiceImpl.java | Service Impl | R06 |
| .../controller/{Entity}Controller.java | Controller | R04 |
| src/test/java/.../controller/{Entity}ControllerTest.java | Test | R09 |
