package com.ljwx.platform.app.dto;

import lombok.Data;

/**
 * 消息记录查询DTO
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Data
public class MsgRecordQueryDTO {

    /**
     * 消息类型: INBOX / EMAIL / SMS
     */
    private String messageType;

    /**
     * 发送状态: PENDING / SUCCESS / FAILURE
     */
    private String sendStatus;

    /**
     * 接收用户ID
     */
    private Long receiverId;

    /**
     * 页码
     */
    private Integer pageNum = 1;

    /**
     * 每页大小
     */
    private Integer pageSize = 10;
}
