package com.ljwx.platform.app.domain.dto;

/**
 * 操作日志查询 DTO。
 */
public class OperationLogQueryDTO {

    /** 页码，默认 1 */
    private int pageNum = 1;

    /** 每页条数，默认 10 */
    private int pageSize = 10;

    /** 操作模块（模糊匹配） */
    private String title;

    /** 操作人员账号（模糊匹配） */
    private String operatorName;

    /** 状态：0-正常, 1-异常 */
    private Integer status;

    /** 开始时间（yyyy-MM-dd） */
    private String startTime;

    /** 结束时间（yyyy-MM-dd） */
    private String endTime;

    public int getPageNum() { return pageNum; }
    public void setPageNum(int pageNum) { this.pageNum = pageNum; }

    public int getPageSize() { return pageSize; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getOperatorName() { return operatorName; }
    public void setOperatorName(String operatorName) { this.operatorName = operatorName; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }

    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }

    public int getOffset() { return (pageNum - 1) * pageSize; }
}
