package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;

/**
 * AI 配置实体
 *
 * @author LJWX Platform
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_ai_config")
public class AiConfig extends BaseEntity {

    /**
     * 模型提供商（OPENAI / TONGYI / DEEPSEEK）
     */
    @TableField("provider")
    private String provider;

    /**
     * 模型名称（如 gpt-4o）
     */
    @TableField("model_name")
    private String modelName;

    /**
     * 加密存储的 API Key
     */
    @TableField("api_key_encrypted")
    private String apiKeyEncrypted;

    /**
     * 自定义 API Base URL（可选）
     */
    @TableField("base_url")
    private String baseUrl;

    /**
     * 温度参数（0.00-1.00）
     */
    @TableField("temperature")
    private BigDecimal temperature;

    /**
     * 最大 Token 数
     */
    @TableField("max_tokens")
    private Integer maxTokens;

    /**
     * 是否启用
     */
    @TableField("enabled")
    private Boolean enabled;
}
