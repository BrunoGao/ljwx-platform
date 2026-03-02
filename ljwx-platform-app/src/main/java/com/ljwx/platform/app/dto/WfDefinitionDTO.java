package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 流程定义 DTO
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
public class WfDefinitionDTO {

    /**
     * 流程标识
     */
    @NotBlank(message = "流程标识不能为空")
    @Size(max = 50, message = "流程标识长度不能超过50")
    private String flowKey;

    /**
     * 流程名称
     */
    @NotBlank(message = "流程名称不能为空")
    @Size(max = 100, message = "流程名称长度不能超过100")
    private String flowName;

    /**
     * 版本号
     */
    @NotNull(message = "版本号不能为空")
    private Integer flowVersion;

    /**
     * 流程配置（JSON格式）
     */
    @NotBlank(message = "流程配置不能为空")
    private String flowConfig;

    /**
     * 状态: DRAFT/PUBLISHED/ARCHIVED
     */
    @NotBlank(message = "状态不能为空")
    @Size(max = 20, message = "状态长度不能超过20")
    private String status;
}
