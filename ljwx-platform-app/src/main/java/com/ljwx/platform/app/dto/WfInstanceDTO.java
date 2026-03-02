package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 流程实例 DTO
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
public class WfInstanceDTO {

    /**
     * 流程定义ID
     */
    @NotNull(message = "流程定义ID不能为空")
    private Long definitionId;

    /**
     * 业务主键
     */
    @NotBlank(message = "业务主键不能为空")
    @Size(max = 100, message = "业务主键长度不能超过100")
    private String businessKey;

    /**
     * 业务类型
     */
    @NotBlank(message = "业务类型不能为空")
    @Size(max = 50, message = "业务类型长度不能超过50")
    private String businessType;
}
