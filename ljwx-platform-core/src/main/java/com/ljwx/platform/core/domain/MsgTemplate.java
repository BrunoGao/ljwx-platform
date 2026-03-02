package com.ljwx.platform.core.domain;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 消息模板实体
 *
 * @author LJWX Platform
 * @since Phase 50
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class MsgTemplate extends BaseEntity {

    /**
     * 主键ID
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
     * 模板类型: INBOX / EMAIL / SMS
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
     * 状态: ENABLED / DISABLED
     */
    private String status;
}
