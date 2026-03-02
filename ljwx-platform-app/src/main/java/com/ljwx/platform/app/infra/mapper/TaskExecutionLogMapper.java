package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.TaskExecutionLog;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 任务执行日志 Mapper
 */
@Mapper
public interface TaskExecutionLogMapper {

    int insert(TaskExecutionLog log);

    int updateById(TaskExecutionLog log);

    int deleteById(Long id);

    TaskExecutionLog selectById(Long id);

    List<TaskExecutionLog> selectList(TaskExecutionLog query);

    long count(TaskExecutionLog query);

    /**
     * 删除指定时间之前的日志
     *
     * @param threshold 时间阈值
     * @return 删除数量
     */
    int deleteByStartTimeBefore(@Param("threshold") LocalDateTime threshold);

    /**
     * 统计任务执行总次数
     *
     * @return 总次数
     */
    Long countTotal();

    /**
     * 统计成功次数
     *
     * @return 成功次数
     */
    Long countSuccess();

    /**
     * 统计失败次数
     *
     * @return 失败次数
     */
    Long countFailure();

    /**
     * 计算平均耗时
     *
     * @return 平均耗时（毫秒）
     */
    Integer avgDuration();

    /**
     * 获取最大耗时
     *
     * @return 最大耗时（毫秒）
     */
    Integer maxDuration();

    /**
     * 获取最小耗时
     *
     * @return 最小耗时（毫秒）
     */
    Integer minDuration();
}
