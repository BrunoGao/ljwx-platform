package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 租户查询 DTO。
 */
@Data
public class TenantQueryDTO {

    private Integer pageNum = 1;
    private Integer pageSize = 10;
    private String name;
    private String code;
    private Integer status;

    public int getOffset() {
        return (Math.max(pageNum, 1) - 1) * Math.max(pageSize, 1);
    }
}
