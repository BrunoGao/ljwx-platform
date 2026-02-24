package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 角色视图对象。
 */
@Data
public class RoleVO {

    private Long id;
    private String name;
    private String code;
    /** 角色描述（对应 sys_role.remark） */
    private String description;
    /** 状态：1-启用，0-禁用 */
    private Integer status;
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
    private List<PermissionVO> permissions;
}
