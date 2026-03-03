package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.PostQueryDTO;
import com.ljwx.platform.app.domain.entity.Post;
import com.ljwx.platform.app.domain.vo.PostVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 岗位 Mapper
 */
@Mapper
public interface PostMapper {

    /**
     * 根据 ID 查询岗位实体
     */
    Post selectById(@Param("id") Long id);

    /**
     * 新增岗位
     */
    int insert(Post post);

    /**
     * 根据 ID 更新岗位
     */
    int updateById(Post post);

    /**
     * 查询岗位列表
     */
    List<PostVO> selectPostList(@Param("query") PostQueryDTO query);

    /**
     * 根据 ID 查询岗位详情
     */
    PostVO selectPostById(@Param("id") Long id);

    /**
     * 根据岗位编码查询岗位（租户内唯一性检查）
     */
    Post selectByPostCode(@Param("postCode") String postCode);

    /**
     * 统计岗位关联的用户数
     */
    Long countUsersByPostId(@Param("postId") Long postId);
}
