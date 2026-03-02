package com.ljwx.platform.app.dto;

import lombok.Data;

/**
 * 消息订阅查询 DTO
 *
 * @author LJWX Platform
 * @since Phase 52
 */
@Data
public class MsgSubscriptionQueryDTO {

    /**
     * 用户 ID
     */
    private Long userId;

    /**
     * 模板 ID
     */
    private Long templateId;

    /**
     * 订阅渠道
     */
    private String channel;

    /**
     * 订阅状态
     */
    private String status;

    /**
     * 页码
     */
    private Integer pageNum = 1;

    /**
     * 每页大小
     */
    private Integer pageSize = 10;
}
