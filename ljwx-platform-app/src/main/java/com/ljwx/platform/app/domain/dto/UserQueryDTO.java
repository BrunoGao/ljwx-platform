package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 用户查询条件（tenant_id 禁止出现，由 TenantLineInterceptor 自动注入）。
 */
@Data
public class UserQueryDTO {

    /** 用户名（模糊查询） */
    private String username;

    /** 昵称（模糊查询） */
    private String nickname;

    /** 状态：1-启用，0-禁用 */
    private Integer status;

    private Integer pageNum = 1;

    private Integer pageSize = 20;

    public int getOffset() {
        return (pageNum - 1) * pageSize;
    }
}
