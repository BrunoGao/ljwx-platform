package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 岗位创建 DTO
 */
@Data
public class PostCreateDTO {

    /**
     * 岗位编码
     */
    @NotBlank(message = "岗位编码不能为空")
    @Size(max = 50, message = "岗位编码长度不能超过50")
    private String postCode;

    /**
     * 岗位名称
     */
    @NotBlank(message = "岗位名称不能为空")
    @Size(max = 100, message = "岗位名称长度不能超过100")
    private String postName;

    /**
     * 显示顺序
     */
    @NotNull(message = "显示顺序不能为空")
    @Min(value = 0, message = "显示顺序不能小于0")
    private Integer postSort;

    /**
     * 状态：ENABLED / DISABLED
     */
    @NotBlank(message = "状态不能为空")
    private String status;

    /**
     * 备注
     */
    @Size(max = 500, message = "备注长度不能超过500")
    private String remark;
}
