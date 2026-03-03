package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.PostCreateDTO;
import com.ljwx.platform.app.domain.dto.PostQueryDTO;
import com.ljwx.platform.app.domain.dto.PostUpdateDTO;
import com.ljwx.platform.app.domain.entity.Post;
import com.ljwx.platform.app.domain.vo.PostVO;
import com.ljwx.platform.app.infra.mapper.PostMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 岗位应用服务
 */
@Service
@RequiredArgsConstructor
public class PostAppService {

    private final PostMapper postMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 查询岗位列表
     */
    public List<PostVO> list(PostQueryDTO query) {
        return postMapper.selectPostList(query);
    }

    /**
     * 根据 ID 查询岗位详情
     */
    public PostVO getById(Long id) {
        PostVO postVO = postMapper.selectPostById(id);
        if (postVO == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "岗位不存在");
        }
        return postVO;
    }

    /**
     * 创建岗位
     */
    @Transactional
    public Long create(PostCreateDTO dto) {
        // BL-40-01: 检查 postCode 唯一性
        Post existingPost = postMapper.selectByPostCode(dto.getPostCode());
        if (existingPost != null) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "岗位编码已存在");
        }

        Post post = new Post();
        post.setId(idGenerator.nextId());
        post.setPostCode(dto.getPostCode());
        post.setPostName(dto.getPostName());
        post.setPostSort(dto.getPostSort());
        post.setStatus(dto.getStatus());
        post.setRemark(dto.getRemark());

        postMapper.insert(post);
        return post.getId();
    }

    /**
     * 更新岗位
     */
    @Transactional
    public void update(Long id, PostUpdateDTO dto) {
        Post post = postMapper.selectById(id);
        if (post == null || post.getDeleted()) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "岗位不存在");
        }

        // BL-40-01: 检查 postCode 唯一性（如果修改了 postCode）
        if (dto.getPostCode() != null && !dto.getPostCode().equals(post.getPostCode())) {
            Post existingPost = postMapper.selectByPostCode(dto.getPostCode());
            if (existingPost != null && !existingPost.getId().equals(id)) {
                throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "岗位编码已存在");
            }
            post.setPostCode(dto.getPostCode());
        }

        if (dto.getPostName() != null) {
            post.setPostName(dto.getPostName());
        }
        if (dto.getPostSort() != null) {
            post.setPostSort(dto.getPostSort());
        }
        if (dto.getStatus() != null) {
            post.setStatus(dto.getStatus());
        }
        if (dto.getRemark() != null) {
            post.setRemark(dto.getRemark());
        }

        postMapper.updateById(post);
    }

    /**
     * 删除岗位
     */
    @Transactional
    public void delete(Long id) {
        Post post = postMapper.selectById(id);
        if (post == null || post.getDeleted()) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "岗位不存在");
        }

        // BL-40-02: 检查是否有关联用户
        Long userCount = postMapper.countUsersByPostId(id);
        if (userCount > 0) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "岗位下存在关联用户，无法删除");
        }

        // 软删除
        post.setDeleted(true);
        postMapper.updateById(post);
    }
}
