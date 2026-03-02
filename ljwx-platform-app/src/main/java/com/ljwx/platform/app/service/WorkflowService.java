package com.ljwx.platform.app.service;

import com.ljwx.platform.app.dto.WfDefinitionDTO;
import com.ljwx.platform.app.dto.WfInstanceDTO;
import com.ljwx.platform.app.dto.WfTaskDTO;
import com.ljwx.platform.app.infra.mapper.WfDefinitionMapper;
import com.ljwx.platform.app.infra.mapper.WfHistoryMapper;
import com.ljwx.platform.app.infra.mapper.WfInstanceMapper;
import com.ljwx.platform.app.infra.mapper.WfTaskMapper;
import com.ljwx.platform.app.vo.WfDefinitionVO;
import com.ljwx.platform.app.vo.WfInstanceVO;
import com.ljwx.platform.app.vo.WfTaskVO;
import com.ljwx.platform.core.domain.WfDefinition;
import com.ljwx.platform.core.domain.WfHistory;
import com.ljwx.platform.core.domain.WfInstance;
import com.ljwx.platform.core.domain.WfTask;
import com.ljwx.platform.web.exception.BusinessException;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 流程引擎服务
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Service
@RequiredArgsConstructor
public class WorkflowService {

    private final WfDefinitionMapper definitionMapper;
    private final WfInstanceMapper instanceMapper;
    private final WfTaskMapper taskMapper;
    private final WfHistoryMapper historyMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 创建流程定义
     */
    @Transactional
    public Long createDefinition(WfDefinitionDTO dto) {
        WfDefinition definition = new WfDefinition();
        BeanUtils.copyProperties(dto, definition);
        definition.setId(idGenerator.nextId());
        definitionMapper.insert(definition);
        return definition.getId();
    }

    /**
     * 更新流程定义
     */
    @Transactional
    public void updateDefinition(Long id, WfDefinitionDTO dto) {
        WfDefinition definition = definitionMapper.selectById(id);
        if (definition == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "流程定义不存在");
        }
        BeanUtils.copyProperties(dto, definition);
        definitionMapper.updateById(definition);
    }

    /**
     * 删除流程定义
     */
    @Transactional
    public void deleteDefinition(Long id) {
        definitionMapper.deleteById(id);
    }

    /**
     * 查询流程定义列表
     */
    public Map<String, Object> listDefinitions(int page, int size, String flowKey, String status) {
        Map<String, Object> params = new HashMap<>();
        params.put("flowKey", flowKey);
        params.put("status", status);
        params.put("limit", size);
        params.put("offset", (page - 1) * size);

        List<WfDefinition> list = definitionMapper.selectList(params);
        long total = definitionMapper.countList(params);

        Map<String, Object> result = new HashMap<>();
        result.put("list", list);
        result.put("total", total);
        return result;
    }

    /**
     * 启动流程实例
     */
    @Transactional
    public Long startInstance(WfInstanceDTO dto, Long userId) {
        WfDefinition definition = definitionMapper.selectById(dto.getDefinitionId());
        if (definition == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "流程定义不存在");
        }
        if (!"PUBLISHED".equals(definition.getStatus())) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "流程定义未发布");
        }

        WfInstance instance = new WfInstance();
        BeanUtils.copyProperties(dto, instance);
        instance.setId(idGenerator.nextId());
        instance.setInitiatorId(userId);
        instance.setStatus("RUNNING");
        instance.setStartTime(LocalDateTime.now());
        instanceMapper.insert(instance);

        recordHistory(instance.getId(), null, "START", userId, "启动流程");

        return instance.getId();
    }

    /**
     * 查询流程实例详情
     */
    public WfInstanceVO getInstance(Long id) {
        WfInstance instance = instanceMapper.selectById(id);
        if (instance == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "流程实例不存在");
        }
        return convertToInstanceVO(instance);
    }

    /**
     * 查询我的待办任务
     */
    public Map<String, Object> getMyTasks(int page, int size, Long userId) {
        Map<String, Object> params = new HashMap<>();
        params.put("assigneeId", userId);
        params.put("status", "PENDING");
        params.put("limit", size);
        params.put("offset", (page - 1) * size);

        List<WfTask> list = taskMapper.selectList(params);
        long total = taskMapper.countList(params);

        Map<String, Object> result = new HashMap<>();
        result.put("list", list);
        result.put("total", total);
        return result;
    }

    /**
     * 审批通过
     */
    @Transactional
    public void approveTask(Long taskId, WfTaskDTO dto, Long userId) {
        WfTask task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "任务不存在");
        }
        if (!"PENDING".equals(task.getStatus())) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "任务已处理");
        }
        if (!task.getAssigneeId().equals(userId)) {
            throw new BusinessException(ErrorCode.PERMISSION_DENIED, "无权处理此任务");
        }

        task.setStatus("APPROVED");
        task.setComment(dto.getComment());
        task.setHandleTime(LocalDateTime.now());
        taskMapper.updateById(task);

        recordHistory(task.getInstanceId(), taskId, "APPROVE", userId, dto.getComment());

        checkInstanceCompletion(task.getInstanceId());
    }

    /**
     * 审批拒绝
     */
    @Transactional
    public void rejectTask(Long taskId, WfTaskDTO dto, Long userId) {
        WfTask task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "任务不存在");
        }
        if (!"PENDING".equals(task.getStatus())) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "任务已处理");
        }
        if (!task.getAssigneeId().equals(userId)) {
            throw new BusinessException(ErrorCode.PERMISSION_DENIED, "无权处理此任务");
        }

        task.setStatus("REJECTED");
        task.setComment(dto.getComment());
        task.setHandleTime(LocalDateTime.now());
        taskMapper.updateById(task);

        WfInstance instance = instanceMapper.selectById(task.getInstanceId());
        instance.setStatus("REJECTED");
        instance.setEndTime(LocalDateTime.now());
        instanceMapper.updateById(instance);

        recordHistory(task.getInstanceId(), taskId, "REJECT", userId, dto.getComment());
    }

    /**
     * 检查流程实例是否完成
     */
    private void checkInstanceCompletion(Long instanceId) {
        Map<String, Object> params = new HashMap<>();
        params.put("instanceId", instanceId);
        params.put("status", "PENDING");
        params.put("limit", 1);
        params.put("offset", 0);

        long pendingCount = taskMapper.countList(params);
        if (pendingCount == 0) {
            WfInstance instance = instanceMapper.selectById(instanceId);
            instance.setStatus("COMPLETED");
            instance.setEndTime(LocalDateTime.now());
            instanceMapper.updateById(instance);
        }
    }

    /**
     * 记录历史
     */
    private void recordHistory(Long instanceId, Long taskId, String action, Long operatorId, String comment) {
        WfHistory history = new WfHistory();
        history.setId(idGenerator.nextId());
        history.setInstanceId(instanceId);
        history.setTaskId(taskId);
        history.setAction(action);
        history.setOperatorId(operatorId);
        history.setComment(comment);
        historyMapper.insert(history);
    }

    /**
     * 转换为 DefinitionVO
     */
    private WfDefinitionVO convertToDefinitionVO(WfDefinition definition) {
        WfDefinitionVO vo = new WfDefinitionVO();
        BeanUtils.copyProperties(definition, vo);
        return vo;
    }

    /**
     * 转换为 InstanceVO
     */
    private WfInstanceVO convertToInstanceVO(WfInstance instance) {
        WfInstanceVO vo = new WfInstanceVO();
        BeanUtils.copyProperties(instance, vo);
        return vo;
    }

    /**
     * 转换为 TaskVO
     */
    private WfTaskVO convertToTaskVO(WfTask task) {
        WfTaskVO vo = new WfTaskVO();
        BeanUtils.copyProperties(task, vo);
        return vo;
    }
}
