package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 更新字典数据请求。
 */
@Data
public class DictDataUpdateDTO {

    @NotNull
    private Long id;

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

    @NotNull
    private Integer version;
}
