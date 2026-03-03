package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 通知用户关联实体，对应 sys_notice_user 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysNoticeUser extends BaseEntity {

    private Long id;

    /** 通知ID */
    private Long noticeId;

    /** 用户ID */
    private Long userId;

    /** 阅读时间，null 表示未读 */
    private LocalDateTime readTime;
}
