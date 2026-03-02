package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 用户收件箱实体
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class MsgUserInbox extends BaseEntity {

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 消息记录ID
     */
    private Long messageId;

    /**
     * 消息标题
     */
    private String title;

    /**
     * 消息内容
     */
    private String content;

    /**
     * 是否已读
     */
    private Boolean isRead;

    /**
     * 阅读时间
     */
    private LocalDateTime readTime;
}
