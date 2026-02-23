package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 系统通知/公告实体，对应 sys_notice 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysNotice extends BaseEntity {

    /** 主键ID（Snowflake） */
    private Long id;

    /** 通知标题 */
    private String noticeTitle;

    /** 通知类型：1-通知, 2-公告 */
    private Integer noticeType;

    /** 通知内容（富文本或纯文本） */
    private String noticeContent;

    /** 状态：0-草稿, 1-已发布, 2-已撤回 */
    private Integer status;

    /** 发布时间（status=1 时自动设置） */
    private LocalDateTime publishTime;
}
