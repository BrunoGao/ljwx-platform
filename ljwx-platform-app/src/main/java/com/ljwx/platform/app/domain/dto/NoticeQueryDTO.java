package com.ljwx.platform.app.domain.dto;

/**
 * 通知/公告查询 DTO。
 */
public class NoticeQueryDTO {

    /** 页码，默认 1 */
    private int pageNum = 1;

    /** 每页条数，默认 10 */
    private int pageSize = 10;

    /** 通知标题（模糊匹配） */
    private String noticeTitle;

    /** 通知类型：1-通知, 2-公告 */
    private Integer noticeType;

    /** 状态：0-草稿, 1-已发布, 2-已撤回 */
    private Integer status;

    public int getPageNum() { return pageNum; }
    public void setPageNum(int pageNum) { this.pageNum = pageNum; }

    public int getPageSize() { return pageSize; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }

    public String getNoticeTitle() { return noticeTitle; }
    public void setNoticeTitle(String noticeTitle) { this.noticeTitle = noticeTitle; }

    public Integer getNoticeType() { return noticeType; }
    public void setNoticeType(Integer noticeType) { this.noticeType = noticeType; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public int getOffset() { return (pageNum - 1) * pageSize; }
}
