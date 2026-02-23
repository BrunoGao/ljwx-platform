package com.ljwx.platform.app.domain.dto;

/**
 * 登录日志查询 DTO。
 */
public class LoginLogQueryDTO {

    /** 页码，默认 1 */
    private int pageNum = 1;

    /** 每页条数，默认 10 */
    private int pageSize = 10;

    /** 登录账号（模糊匹配） */
    private String username;

    /** 状态：0-成功, 1-失败 */
    private Integer status;

    /** 开始时间（yyyy-MM-dd） */
    private String startTime;

    /** 结束时间（yyyy-MM-dd） */
    private String endTime;

    public int getPageNum() { return pageNum; }
    public void setPageNum(int pageNum) { this.pageNum = pageNum; }

    public int getPageSize() { return pageSize; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }

    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }

    public int getOffset() { return (pageNum - 1) * pageSize; }
}
