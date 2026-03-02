package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 消息模板VO
 *
 * @author LJWX Platform
 * @since Phase 50
 */
@Data
public class MsgTemplateVO {

    /**
     * 主键
     */
    private Long id;

    /**
     * 模板编码
     */
    private String templateCode;

    /**
     * 模板名称
     */
    private String templateName;

    /**
     * 模板类型
     */
    private String templateType;

    /**
     * 邮件主题
     */
    private String subject;

    /**
     * 模板内容
     */
    private String content;

    /**
     * JSON数组，变量列表
     */
    private String variables;

    /**
     * 状态
     */
    private String status;

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    private LocalDateTime updatedTime;
}
