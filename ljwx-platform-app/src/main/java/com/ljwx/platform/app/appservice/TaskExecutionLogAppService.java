package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.TaskExecutionLogQueryDTO;
import com.ljwx.platform.app.domain.entity.TaskExecutionLog;
import com.ljwx.platform.app.domain.vo.TaskExecutionLogVO;
import com.ljwx.platform.app.domain.vo.TaskLogStatsVO;
import com.ljwx.platform.app.infra.mapper.TaskExecutionLogMapper;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 任务执行日志应用服务
 */
@Service
@RequiredArgsConstructor
public class TaskExecutionLogAppService {

    private final TaskExecutionLogMapper taskExecutionLogMapper;

    /**
     * 分页查询任务执行日志
     *
     * @param query 查询条件
     * @return 分页结果
     */
    public PageResult<TaskExecutionLogVO> list(TaskExecutionLogQueryDTO query) {
        TaskExecutionLog queryEntity = new TaskExecutionLog();
        // Set query parameters based on DTO
        List<TaskExecutionLog> logs = taskExecutionLogMapper.selectList(queryEntity);
        long total = taskExecutionLogMapper.count(queryEntity);

        List<TaskExecutionLogVO> vos = logs.stream()
                .map(this::convertToVO)
                .collect(Collectors.toList());

        return new PageResult<>(vos, total);
    }

    private TaskExecutionLogVO convertToVO(TaskExecutionLog log) {
        TaskExecutionLogVO vo = new TaskExecutionLogVO();
        vo.setId(log.getId());
        vo.setTaskName(log.getTaskName());
        vo.setTaskGroup(log.getTaskGroup());
        vo.setStatus(log.getStatus());
        vo.setStartTime(log.getStartTime());
        vo.setEndTime(log.getEndTime());
        vo.setDuration(log.getDuration());
        vo.setErrorMessage(log.getErrorMessage());
        return vo;
    }

    /**
     * 查询任务执行日志详情
     *
     * @param id 日志 ID
     * @return 日志详情
     */
    public TaskExecutionLogVO getById(Long id) {
        TaskExecutionLog entity = taskExecutionLogMapper.selectById(id);
        if (entity == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "任务执行日志不存在");
        }
        return toVO(entity);
    }

    /**
     * 删除任务执行日志
     *
     * @param id 日志 ID
     */
    @Transactional
    public void delete(Long id) {
        TaskExecutionLog entity = taskExecutionLogMapper.selectById(id);
        if (entity == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "任务执行日志不存在");
        }
        taskExecutionLogMapper.deleteById(id);
    }

    /**
     * 清理历史日志（30 天前）
     *
     * @return 清理数量
     */
    @Transactional
    public Integer cleanOldLogs() {
        LocalDateTime threshold = LocalDateTime.now().minusDays(30);
        return taskExecutionLogMapper.deleteByStartTimeBefore(threshold);
    }

    /**
     * 获取任务执行统计
     *
     * @return 统计结果
     */
    public TaskLogStatsVO getStats() {
        return TaskLogStatsVO.builder()
                .totalCount(taskExecutionLogMapper.countTotal())
                .successCount(taskExecutionLogMapper.countSuccess())
                .failureCount(taskExecutionLogMapper.countFailure())
                .avgDuration(taskExecutionLogMapper.avgDuration())
                .maxDuration(taskExecutionLogMapper.maxDuration())
                .minDuration(taskExecutionLogMapper.minDuration())
                .build();
    }

    /**
     * 实体转 VO
     */
    private TaskExecutionLogVO toVO(TaskExecutionLog entity) {
        return TaskExecutionLogVO.builder()
                .id(entity.getId())
                .taskName(entity.getTaskName())
                .taskGroup(entity.getTaskGroup())
                .taskParams(entity.getTaskParams())
                .status(entity.getStatus())
                .startTime(entity.getStartTime())
                .endTime(entity.getEndTime())
                .duration(entity.getDuration())
                .result(entity.getResult())
                .errorMessage(entity.getErrorMessage())
                .errorStack(entity.getErrorStack())
                .serverIp(entity.getServerIp())
                .serverName(entity.getServerName())
                .createdTime(entity.getCreatedTime())
                .build();
    }
}
