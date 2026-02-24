package com.ljwx.platform.app.domain.dto;

/**
 * 租户套餐查询条件（tenant_id 禁止出现，由 TenantLineInterceptor 自动注入）
 */
public class TenantPackageQueryDTO {

    private String name;

    private Integer status;

    private int pageNum = 1;

    private int pageSize = 10;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public int getPageNum() { return pageNum; }
    public void setPageNum(int pageNum) { this.pageNum = pageNum; }

    public int getPageSize() { return pageSize; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }

    public int getOffset() { return (pageNum - 1) * pageSize; }
}
