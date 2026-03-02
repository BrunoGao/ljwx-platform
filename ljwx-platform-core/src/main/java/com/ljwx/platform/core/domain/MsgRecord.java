package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 消息记录实体
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class MsgRecord extends BaseEntity {

    /**
     * 消息模板ID
     */
    private Long templateId;

    /**
     * 消息类型: INBOX / EMAIL / SMS
     */
    private String messageType;

    /**
     * 接收用户ID
     */
    private Long receiverId;

    /**
     * 接收地址（邮箱/手机号）
     */
    private String receiverAddress;

    /**
     * 消息主题
     */
    private String subject;

    /**
     * 消息内容
     */
    private String content;

    /**
     * 发送状态: PENDING / SUCCESS / FAILURE
     */
    private String sendStatus;

    /**
     * 发送成功时间
     */
    private LocalDateTime sendTime;

    /**
     * 错误信息
     */
    private String errorMessage;
}
