package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 更新部门请求（tenant_id 禁止出现，由后端自动注入）
 */
@Data
public class DeptUpdateDTO {

    @NotNull
    private Long parentId;

    @NotBlank
    private String name;

    private Integer sort;

    private String leader;

    private String phone;

    private String email;

    private Integer status;

    @NotNull
    private Integer version;
}
