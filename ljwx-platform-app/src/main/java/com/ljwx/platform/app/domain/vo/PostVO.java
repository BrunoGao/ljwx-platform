package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 岗位 VO
 */
@Data
public class PostVO {

    /**
     * 主键
     */
    private Long id;

    /**
     * 岗位编码
     */
    private String postCode;

    /**
     * 岗位名称
     */
    private String postName;

    /**
     * 显示顺序
     */
    private Integer postSort;

    /**
     * 状态：ENABLED / DISABLED
     */
    private String status;

    /**
     * 备注
     */
    private String remark;

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    private LocalDateTime updatedTime;
}
