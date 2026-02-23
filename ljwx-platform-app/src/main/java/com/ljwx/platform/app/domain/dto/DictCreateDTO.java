package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 创建字典类型请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class DictCreateDTO {

    @NotBlank
    private String dictName;

    @NotBlank
    private String dictType;

    private Integer status = 1;

    private String remark;
}
