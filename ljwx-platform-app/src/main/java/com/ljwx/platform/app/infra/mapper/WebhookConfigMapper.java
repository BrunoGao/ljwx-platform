package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.dto.WebhookConfigQueryDTO;
import com.ljwx.platform.app.vo.WebhookConfigVO;
import com.ljwx.platform.app.domain.entity.WebhookConfig;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * Webhook Configuration Mapper
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Mapper
public interface WebhookConfigMapper {

    /**
     * Insert webhook config
     */
    void insert(WebhookConfig config);

    /**
     * Update webhook config by ID
     */
    void updateById(WebhookConfig config);

    /**
     * Delete webhook config by ID (soft delete)
     */
    void deleteById(@Param("id") Long id);

    /**
     * Select webhook config by ID
     */
    WebhookConfig selectById(@Param("id") Long id);

    /**
     * Query webhook config list
     *
     * @param query query conditions
     * @return webhook config list
     */
    List<WebhookConfigVO> selectWebhookConfigList(@Param("query") WebhookConfigQueryDTO query);

    /**
     * Count webhook configs
     *
     * @param query query conditions
     * @return total count
     */
    long countWebhookConfigs(@Param("query") WebhookConfigQueryDTO query);

    /**
     * Query webhook config by ID
     *
     * @param id webhook config ID
     * @return webhook config VO
     */
    WebhookConfigVO selectWebhookConfigById(@Param("id") Long id);

    /**
     * Query enabled webhook configs by event type
     *
     * @param eventType event type
     * @return webhook config list
     */
    List<WebhookConfig> selectEnabledByEventType(@Param("eventType") String eventType);
}
