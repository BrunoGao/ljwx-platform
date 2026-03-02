package com.ljwx.platform.app.appservice;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.ljwx.platform.app.domain.dto.TaskExecutionLogQueryDTO;
import com.ljwx.platform.app.domain.entity.TaskExecutionLog;
import com.ljwx.platform.app.domain.vo.TaskExecutionLogVO;
import com.ljwx.platform.app.domain.vo.TaskLogStatsVO;
import com.ljwx.platform.app.infra.mapper.TaskExecutionLogMapper;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

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
    public IPage<TaskExecutionLogVO> list(TaskExecutionLogQueryDTO query) {
        LambdaQueryWrapper<TaskExecutionLog> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(StringUtils.hasText(query.getTaskName()), TaskExecutionLog::getTaskName, query.getTaskName())
                .eq(StringUtils.hasText(query.getTaskGroup()), TaskExecutionLog::getTaskGroup, query.getTaskGroup())
                .eq(StringUtils.hasText(query.getStatus()), TaskExecutionLog::getStatus, query.getStatus())
                .ge(query.getStartTimeBegin() != null, TaskExecutionLog::getStartTime, query.getStartTimeBegin())
                .le(query.getStartTimeEnd() != null, TaskExecutionLog::getStartTime, query.getStartTimeEnd())
                .orderByDesc(TaskExecutionLog::getStartTime);

        Page<TaskExecutionLog> page = new Page<>(query.getPageNum(), query.getPageSize());
        IPage<TaskExecutionLog> result = taskExecutionLogMapper.selectPage(page, wrapper);

        return result.convert(this::toVO);
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
            throw new BusinessException("任务执行日志不存在");
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
            throw new BusinessException("任务执行日志不存在");
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
