# ADR-0009: 部门负责人采用 `leader_user_id` 主语义，`sys_dept_leader` 为可选扩展

## Status
Accepted

## Context
原 leader VARCHAR 不可用于审批人解析与权限计算；多负责人需求不确定。

在原有设计中,`sys_dept.leader` 是 VARCHAR 类型,存储负责人姓名:
- 无法用于审批人解析 (需要 user_id)
- 无法用于权限计算 (需要关联用户表)
- 无法支持多负责人场景

### 问题场景
1. **审批流程**: "部门负责人审批" 无法解析为具体用户
2. **权限控制**: "部门负责人可查看本部门数据" 无法实现
3. **多负责人**: 部门有正副负责人,原设计无法支持

## Decision
`sys_dept.leader_user_id` 为主负责人；如需正副负责人再启用 `sys_dept_leader`。

### 数据模型

#### 方案 1: 单负责人 (推荐)
```sql
ALTER TABLE sys_dept
ADD COLUMN leader_user_id BIGINT COMMENT '负责人用户ID';

-- 废弃原 leader 字段 (保留只读,用于数据迁移)
-- ALTER TABLE sys_dept DROP COLUMN leader;
```

#### 方案 2: 多负责人 (可选扩展)
```sql
CREATE TABLE sys_dept_leader (
    id BIGINT PRIMARY KEY,
    dept_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    leader_type VARCHAR(20) NOT NULL,  -- PRIMARY/DEPUTY
    sort_order INT DEFAULT 0,
    tenant_id BIGINT NOT NULL,
    created_by BIGINT NOT NULL,
    created_time TIMESTAMP NOT NULL,
    updated_by BIGINT NOT NULL,
    updated_time TIMESTAMP NOT NULL,
    deleted BOOLEAN DEFAULT FALSE,
    version INT DEFAULT 0,
    UNIQUE KEY uk_dept_user (dept_id, user_id, deleted)
);
```

### 审批人解析

#### 单负责人场景
```java
public Long resolveDeptLeader(Long deptId) {
    Dept dept = deptRepository.findById(deptId);
    return dept.getLeaderUserId();
}
```

#### 多负责人场景
```java
public List<Long> resolveDeptLeaders(Long deptId) {
    return deptLeaderRepository.findByDeptId(deptId)
        .stream()
        .map(DeptLeader::getUserId)
        .collect(Collectors.toList());
}
```

## Consequences

### 正面影响
- 支持审批人解析和权限计算
- 保持简单,满足大部分场景
- 可选扩展多负责人,不影响现有功能

### 负面影响
- 部门维护 UI/接口需要能选择用户
- 数据迁移需要处理原 leader 文本字段（废弃或保留只读）
- 多负责人场景需要额外开发

### 实施要点

#### 1. 数据迁移
```sql
-- 迁移脚本 (如果原 leader 是用户名)
UPDATE sys_dept d
SET leader_user_id = (
    SELECT u.id FROM sys_user u
    WHERE u.username = d.leader
    LIMIT 1
)
WHERE d.leader IS NOT NULL;
```

#### 2. 部门维护 UI
- 负责人选择: 下拉框选择用户 (支持搜索)
- 显示: 用户名 + 工号
- 验证: 负责人必须属于本租户

#### 3. 审批流程配置
- 审批人类型: 部门负责人
- 解析逻辑: 根据发起人部门查找 leader_user_id
- 多负责人: 支持会签/或签

#### 4. 权限控制
- 数据权限: 部门负责人可查看本部门及下级部门数据
- 功能权限: 部门负责人可管理本部门用户

## References
- Phase 40: 岗位管理 (部门相关)
- spec/phase/phase-40.md
