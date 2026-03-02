package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 消息记录VO
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Data
public class MsgRecordVO {

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 消息模板ID
     */
    private Long templateId;

    /**
     * 消息类型
     */
    private String messageType;

    /**
     * 接收用户ID
     */
    private Long receiverId;

    /**
     * 接收地址
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
     * 发送状态
     */
    private String sendStatus;

    /**
     * 发送时间
     */
    private LocalDateTime sendTime;

    /**
     * 错误信息
     */
    private String errorMessage;

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;
}
