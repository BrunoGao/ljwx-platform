package com.ljwx.platform.app.dto;

import lombok.Data;

/**
 * 消息模板查询DTO
 *
 * @author LJWX Platform
 * @since Phase 50
 */
@Data
public class MsgTemplateQueryDTO {

    /**
     * 模板编码（模糊查询）
     */
    private String templateCode;

    /**
     * 模板名称（模糊查询）
     */
    private String templateName;

    /**
     * 模板类型
     */
    private String templateType;

    /**
     * 状态
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
