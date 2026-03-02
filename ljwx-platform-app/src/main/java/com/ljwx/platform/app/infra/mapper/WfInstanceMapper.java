package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.domain.WfInstance;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 流程实例 Mapper
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Mapper
public interface WfInstanceMapper {

    /**
     * 插入流程实例
     */
    void insert(WfInstance instance);

    /**
     * 根据ID查询
     */
    WfInstance selectById(@Param("id") Long id);

    /**
     * 更新流程实例
     */
    void updateById(WfInstance instance);

    /**
     * 删除流程实例
     */
    void deleteById(@Param("id") Long id);

    /**
     * 查询流程实例列表
     */
    List<WfInstance> selectList(Map<String, Object> params);

    /**
     * 统计流程实例数量
     */
    long countList(Map<String, Object> params);
}
