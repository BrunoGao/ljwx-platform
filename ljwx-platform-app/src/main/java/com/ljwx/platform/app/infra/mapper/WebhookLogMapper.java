package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.dto.WebhookLogQueryDTO;
import com.ljwx.platform.app.vo.WebhookLogVO;
import com.ljwx.platform.core.domain.WebhookLog;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * Webhook Log Mapper
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Mapper
public interface WebhookLogMapper {

    /**
     * Insert webhook log
     */
    void insert(WebhookLog log);

    /**
     * Query webhook log list
     *
     * @param query query conditions
     * @return webhook log list
     */
    List<WebhookLogVO> selectWebhookLogList(@Param("query") WebhookLogQueryDTO query);

    /**
     * Count webhook logs
     *
     * @param query query conditions
     * @return total count
     */
    long countWebhookLogs(@Param("query") WebhookLogQueryDTO query);
}
