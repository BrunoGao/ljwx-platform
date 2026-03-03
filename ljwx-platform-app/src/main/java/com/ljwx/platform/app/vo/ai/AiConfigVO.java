package com.ljwx.platform.app.vo.ai;

import lombok.Data;

import java.math.BigDecimal;

/**
 * AI 配置 VO
 *
 * @author LJWX Platform
 */
@Data
public class AiConfigVO {

    /**
     * 模型提供商
     */
    private String provider;

    /**
     * 模型名称
     */
    private String modelName;

    /**
     * 脱敏 API Key（sk-***...***xxxx）
     */
    private String apiKeyMasked;

    /**
     * Base URL
     */
    private String baseUrl;

    /**
     * 温度参数
     */
    private BigDecimal temperature;

    /**
     * 最大 Token 数
     */
    private Integer maxTokens;

    /**
     * 是否启用
     */
    private Boolean enabled;
}
