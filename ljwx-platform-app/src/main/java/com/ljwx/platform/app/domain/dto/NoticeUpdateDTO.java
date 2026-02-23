package com.ljwx.platform.app.domain.dto;

/**
 * 通知/公告更新 DTO。
 */
public class NoticeUpdateDTO {

    /** 主键 ID（由 Controller 从 PathVariable 注入） */
    private Long id;

    /** 乐观锁版本号 */
    private Integer version;

    /** 通知标题 */
    private String noticeTitle;

    /** 通知类型：1-通知, 2-公告 */
    private Integer noticeType;

    /** 通知内容 */
    private String noticeContent;

    /** 状态：0-草稿, 1-已发布, 2-已撤回 */
    private Integer status;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }

    public String getNoticeTitle() { return noticeTitle; }
    public void setNoticeTitle(String noticeTitle) { this.noticeTitle = noticeTitle; }

    public Integer getNoticeType() { return noticeType; }
    public void setNoticeType(Integer noticeType) { this.noticeType = noticeType; }

    public String getNoticeContent() { return noticeContent; }
    public void setNoticeContent(String noticeContent) { this.noticeContent = noticeContent; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
}
