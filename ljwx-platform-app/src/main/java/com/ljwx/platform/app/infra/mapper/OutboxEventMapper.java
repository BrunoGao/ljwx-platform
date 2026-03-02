package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.event.OutboxEvent;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Outbox 事件 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface OutboxEventMapper {

    int insert(OutboxEvent event);

    int updateById(OutboxEvent event);

    OutboxEvent selectById(Long id);

    /**
     * 查询待发送的事件（PENDING 且 next_retry_time <= now）。
     *
     * @param now       当前时间
     * @param batchSize 批量大小
     * @return 待发送事件列表
     */
    List<OutboxEvent> selectPendingEvents(@Param("now") LocalDateTime now, @Param("batchSize") int batchSize);

    /**
     * 更新事件状态为 SENT。
     *
     * @param id       事件 ID
     * @param sentTime 发送时间
     * @return 更新行数
     */
    int markAsSent(@Param("id") Long id, @Param("sentTime") LocalDateTime sentTime);

    /**
     * 更新事件状态为 FAILED。
     *
     * @param id           事件 ID
     * @param errorMessage 错误信息
     * @return 更新行数
     */
    int markAsFailed(@Param("id") Long id, @Param("errorMessage") String errorMessage);

    /**
     * 增加重试次数并更新下次重试时间。
     *
     * @param id            事件 ID
     * @param retryCount    新的重试次数
     * @param nextRetryTime 下次重试时间
     * @return 更新行数
     */
    int incrementRetry(@Param("id") Long id,
                       @Param("retryCount") int retryCount,
                       @Param("nextRetryTime") LocalDateTime nextRetryTime);

    /**
     * 删除指定时间之前的 SENT 事件（定期清理）。
     *
     * @param before 截止时间
     * @return 删除行数
     */
    int deleteSentEventsBefore(@Param("before") LocalDateTime before);
}
