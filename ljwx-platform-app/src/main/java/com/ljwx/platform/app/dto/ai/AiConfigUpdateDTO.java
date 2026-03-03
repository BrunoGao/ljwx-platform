package com.ljwx.platform.app.dto.ai;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;

/**
 * AI 配置更新 DTO
 *
 * @author LJWX Platform
 */
@Data
public class AiConfigUpdateDTO {

    /**
     * 模型提供商
     */
    @NotBlank(message = "模型提供商不能为空")
    @Pattern(regexp = "OPENAI|TONGYI|DEEPSEEK", message = "模型提供商必须是 OPENAI、TONGYI 或 DEEPSEEK")
    private String provider;

    /**
     * 模型名称
     */
    @NotBlank(message = "模型名称不能为空")
    @Size(max = 100, message = "模型名称长度不能超过 100 个字符")
    @Pattern(regexp = "[a-zA-Z0-9._-]+", message = "模型名称仅允许字母、数字、点、下划线、短横线")
    private String modelName;

    /**
     * API Key（明文，后端加密存储）
     */
    @NotBlank(message = "API Key 不能为空")
    @Size(min = 20, max = 500, message = "API Key 长度必须在 20-500 个字符之间")
    private String apiKey;

    /**
     * 自定义 Base URL
     */
    @Size(max = 500, message = "Base URL 长度不能超过 500 个字符")
    @Pattern(regexp = "https?://.*", message = "Base URL 必须以 http:// 或 https:// 开头")
    private String baseUrl;

    /**
     * 温度参数
     */
    @DecimalMin(value = "0.0", message = "温度参数不能小于 0.0")
    @DecimalMax(value = "1.0", message = "温度参数不能大于 1.0")
    private BigDecimal temperature;

    /**
     * 最大 Token 数
     */
    @Min(value = 256, message = "最大 Token 数不能小于 256")
    @Max(value = 8192, message = "最大 Token 数不能大于 8192")
    private Integer maxTokens;
}
