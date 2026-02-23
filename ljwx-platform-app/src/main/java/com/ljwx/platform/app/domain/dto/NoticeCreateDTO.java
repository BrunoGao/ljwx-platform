package com.ljwx.platform.app.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 通知/公告创建 DTO。
 */
public class NoticeCreateDTO {

    /** 通知标题 */
    @NotBlank(message = "通知标题不能为空")
    private String noticeTitle;

    /** 通知类型：1-通知, 2-公告 */
    @NotNull(message = "通知类型不能为空")
    private Integer noticeType;

    /** 通知内容 */
    private String noticeContent;

    /** 状态：0-草稿, 1-已发布（默认草稿） */
    private Integer status;

    public String getNoticeTitle() { return noticeTitle; }
    public void setNoticeTitle(String noticeTitle) { this.noticeTitle = noticeTitle; }

    public Integer getNoticeType() { return noticeType; }
    public void setNoticeType(Integer noticeType) { this.noticeType = noticeType; }

    public String getNoticeContent() { return noticeContent; }
    public void setNoticeContent(String noticeContent) { this.noticeContent = noticeContent; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
}
