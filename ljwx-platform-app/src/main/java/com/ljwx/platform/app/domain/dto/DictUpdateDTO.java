package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 更新字典类型请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class DictUpdateDTO {

    @NotNull
    private Long id;

    @NotBlank
    private String dictName;

    @NotBlank
    private String dictType;

    private Integer status;

    private String remark;

    @NotNull
    private Integer version;
}
