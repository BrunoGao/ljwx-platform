# ADR-0008: 工作流实例可见性采用 6 级模型（含可选部门范围管理）

## Status
Accepted

## Context
审批"能看到任务但看不到表单/附件"常见且致命。

在工作流系统中,常见的可见性问题:
1. **任务可见,表单不可见**: 用户能看到待办任务,但点击后无权查看表单
2. **历史办理人无权查看**: 已审批的用户无法查看后续流程
3. **抄送人权限不明确**: 抄送人能否查看表单和附件?
4. **部门负责人无权查看**: 部门负责人无法查看下属发起的流程

这些问题会导致严重的用户体验问题和业务流程阻塞。

## Decision
定义并强制实现 6 级可见性：发起人/当前办理/历史办理/抄送/流程管理员/（可选）部门范围管理员。

### 6 级可见性模型

| 级别 | 角色 | 可见范围 | 权限 |
|------|------|----------|------|
| 1 | 发起人 | 自己发起的流程 | 查看表单、附件、流程图、审批历史 |
| 2 | 当前办理人 | 待办任务对应的流程 | 查看表单、附件、审批、驳回、转办 |
| 3 | 历史办理人 | 已办理的流程 | 查看表单、附件、流程图、审批历史 |
| 4 | 抄送人 | 被抄送的流程 | 查看表单、附件、流程图、审批历史 |
| 5 | 流程管理员 | 所有流程 | 查看、终止、删除、导出 |
| 6 | 部门范围管理员 | 本部门及下级部门的流程 | 查看表单、附件、流程图、审批历史 |

### 实现方案

#### 1. 可见性判定接口
```java
public interface WorkflowVisibilityService {
    /**
     * 判断用户是否可见流程实例
     */
    boolean canView(Long userId, Long processInstanceId);

    /**
     * 获取用户可见的流程实例列表
     */
    List<Long> getVisibleProcessInstanceIds(Long userId, WorkflowQueryDTO query);
}
```

#### 2. 可见性判定逻辑
```java
public boolean canView(Long userId, Long processInstanceId) {
    ProcessInstance instance = processInstanceRepository.findById(processInstanceId);

    // 1. 发起人
    if (instance.getStartUserId().equals(userId)) {
        return true;
    }

    // 2. 当前办理人
    if (taskRepository.existsByProcessInstanceIdAndAssignee(processInstanceId, userId)) {
        return true;
    }

    // 3. 历史办理人
    if (historyTaskRepository.existsByProcessInstanceIdAndAssignee(processInstanceId, userId)) {
        return true;
    }

    // 4. 抄送人
    if (ccRepository.existsByProcessInstanceIdAndUserId(processInstanceId, userId)) {
        return true;
    }

    // 5. 流程管理员
    if (hasPermission(userId, "workflow:process:manage")) {
        return true;
    }

    // 6. 部门范围管理员 (可选)
    if (isDeptScopeManager(userId, instance.getStartUserId())) {
        return true;
    }

    return false;
}
```

#### 3. 部门范围管理员判定
```java
private boolean isDeptScopeManager(Long managerId, Long startUserId) {
    // 获取发起人的部门
    User startUser = userRepository.findById(startUserId);
    Long startDeptId = startUser.getDeptId();

    // 获取管理员的部门
    User manager = userRepository.findById(managerId);
    Long managerDeptId = manager.getDeptId();

    // 判断发起人部门是否在管理员部门的范围内
    return deptService.isAncestor(managerDeptId, startDeptId);
}
```

## Consequences

### 正面影响
- 统一的可见性模型,避免权限混乱
- 所有查询接口强制走可见性判定,防止越权
- 支持部门范围管理,满足组织管理需求

### 负面影响
- 工作流查询接口必须统一走可见性判定
- 需要明确 `leader_user_id` 等组织字段支撑审批人解析
- 可见性判定可能影响查询性能 (需要优化)

### 实施要点

#### 1. 强制可见性判定
- 所有工作流查询接口必须调用 `canView()` 或 `getVisibleProcessInstanceIds()`
- 禁止直接查询 `wf_process_instance` 表

#### 2. 性能优化
- 使用 Redis 缓存可见性判定结果 (TTL 60s)
- 批量查询时使用 `getVisibleProcessInstanceIds()` 预过滤

#### 3. 审计日志
- 记录所有可见性判定失败的尝试
- 监控越权访问尝试

## References
- Phase 26: 工作流引擎
- spec/phase/phase-26.md
