package com.ljwx.platform.app.dto;

import lombok.Data;

/**
 * 用户收件箱查询DTO
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Data
public class MsgUserInboxQueryDTO {

    /**
     * 用户ID（从SecurityContext获取，不需要前端传递）
     */
    private Long userId;

    /**
     * 是否已读
     */
    private Boolean isRead;

    /**
     * 页码
     */
    private Integer pageNum = 1;

    /**
     * 每页大小
     */
    private Integer pageSize = 10;
}
