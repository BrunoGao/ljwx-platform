package com.ljwx.platform.app.domain.dto;

import lombok.Data;

/**
 * 岗位查询 DTO
 */
@Data
public class PostQueryDTO {

    /**
     * 岗位编码（模糊查询）
     */
    private String postCode;

    /**
     * 岗位名称（模糊查询）
     */
    private String postName;

    /**
     * 状态
     */
    private String status;
}
