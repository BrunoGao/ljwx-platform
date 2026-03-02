package com.ljwx.platform.core.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Webhook Configuration Entity
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_webhook_config")
public class WebhookConfig extends BaseEntity {

    /**
     * Primary Key (Snowflake ID)
     */
    @TableId
    private Long id;

    /**
     * Webhook Name
     */
    private String webhookName;

    /**
     * Webhook URL
     */
    private String webhookUrl;

    /**
     * Event Types (JSON array)
     */
    private String eventTypes;

    /**
     * Secret Key for HMAC signature
     */
    private String secretKey;

    /**
     * Status: ENABLED / DISABLED
     */
    private String status;

    /**
     * Max Retry Count (default: 5)
     */
    private Integer retryCount;

    /**
     * Timeout in seconds (default: 5)
     */
    private Integer timeoutSeconds;
}
