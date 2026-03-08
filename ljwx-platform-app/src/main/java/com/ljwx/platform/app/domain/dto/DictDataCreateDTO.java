package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 创建字典数据请求。
 */
@Data
public class DictDataCreateDTO {

    @NotBlank
    private String dictType;

    @NotBlank
    private String dictLabel;

    @NotBlank
    private String dictValue;

    private Integer sortOrder = 0;

    private Integer status = 1;

    private String cssClass;

    private String listClass;

    private Boolean isDefault = Boolean.FALSE;

    private String remark;
}
