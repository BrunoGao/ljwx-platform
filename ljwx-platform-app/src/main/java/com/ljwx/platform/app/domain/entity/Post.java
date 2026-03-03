package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 岗位实体
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class Post extends BaseEntity {

    /**
     * 主键（雪花 ID）
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
}
