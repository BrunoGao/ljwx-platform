package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 用户岗位关联实体
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class UserPost extends BaseEntity {

    /**
     * 主键（雪花 ID）
     */
    private Long id;

    /**
     * 用户 ID
     */
    private Long userId;

    /**
     * 岗位 ID
     */
    private Long postId;
}
