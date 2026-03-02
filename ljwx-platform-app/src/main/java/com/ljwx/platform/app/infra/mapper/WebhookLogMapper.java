package com.ljwx.platform.app.infra.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ljwx.platform.app.dto.WebhookLogQueryDTO;
import com.ljwx.platform.app.vo.WebhookLogVO;
import com.ljwx.platform.app.domain.entity.WebhookLog;
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
public interface WebhookLogMapper extends BaseMapper<WebhookLog> {

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
