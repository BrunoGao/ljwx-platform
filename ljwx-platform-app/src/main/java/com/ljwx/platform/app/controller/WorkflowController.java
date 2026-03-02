package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.WfDefinitionDTO;
import com.ljwx.platform.app.dto.WfInstanceDTO;
import com.ljwx.platform.app.dto.WfTaskDTO;
import com.ljwx.platform.app.service.WorkflowService;
import com.ljwx.platform.app.vo.WfInstanceVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 流程引擎控制器
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@RestController
@RequestMapping("/api/v1/workflows")
@RequiredArgsConstructor
public class WorkflowController {

    private final WorkflowService workflowService;

    /**
     * 创建流程定义
     */
    @PostMapping("/definitions") @PreAuthorize("hasAuthority('system:workflow:definition:add')")
    public Result<Long> createDefinition(@Valid @RequestBody WfDefinitionDTO dto) {
        Long id = workflowService.createDefinition(dto);
        return Result.ok(id);
    }

    /**
     * 更新流程定义
     */
    @PutMapping("/definitions/{id}") @PreAuthorize("hasAuthority('system:workflow:definition:edit')")
    public Result<Void> updateDefinition(@PathVariable Long id, @Valid @RequestBody WfDefinitionDTO dto) {
        workflowService.updateDefinition(id, dto);
        return Result.ok();
    }

    /**
     * 删除流程定义
     */
    @DeleteMapping("/definitions/{id}") @PreAuthorize("hasAuthority('system:workflow:definition:delete')")
    public Result<Void> deleteDefinition(@PathVariable Long id) {
        workflowService.deleteDefinition(id);
        return Result.ok();
    }

    /**
     * 查询流程定义列表
     */
    @GetMapping("/definitions") @PreAuthorize("hasAuthority('system:workflow:definition:list')")
    public Result<Map<String, Object>> listDefinitions(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) String flowKey,
            @RequestParam(required = false) String status) {
        Map<String, Object> result = workflowService.listDefinitions(page, size, flowKey, status);
        return Result.ok(result);
    }

    /**
     * 启动流程实例
     */
    @PostMapping("/instances") @PreAuthorize("hasAuthority('system:workflow:instance:add')")
    public Result<Long> startInstance(@Valid @RequestBody WfInstanceDTO dto, Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        Long id = workflowService.startInstance(dto, userId);
        return Result.ok(id);
    }

    /**
     * 查询流程实例详情
     */
    @GetMapping("/instances/{id}") @PreAuthorize("hasAuthority('system:workflow:instance:query')")
    public Result<WfInstanceVO> getInstance(@PathVariable Long id) {
        WfInstanceVO vo = workflowService.getInstance(id);
        return Result.ok(vo);
    }

    /**
     * 查询我的待办任务
     */
    @GetMapping("/tasks/my") @PreAuthorize("hasAuthority('system:workflow:task:list')")
    public Result<Map<String, Object>> getMyTasks(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        Map<String, Object> result = workflowService.getMyTasks(page, size, userId);
        return Result.ok(result);
    }

    /**
     * 审批通过
     */
    @PostMapping("/tasks/{id}/approve") @PreAuthorize("hasAuthority('system:workflow:task:approve')")
    public Result<Void> approveTask(@PathVariable Long id, @RequestBody WfTaskDTO dto, Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        workflowService.approveTask(id, dto, userId);
        return Result.ok();
    }

    /**
     * 审批拒绝
     */
    @PostMapping("/tasks/{id}/reject") @PreAuthorize("hasAuthority('system:workflow:task:reject')")
    public Result<Void> rejectTask(@PathVariable Long id, @RequestBody WfTaskDTO dto, Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        workflowService.rejectTask(id, dto, userId);
        return Result.ok();
    }
}
