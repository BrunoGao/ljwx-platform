package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.domain.WfDefinition;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 流程定义 Mapper
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Mapper
public interface WfDefinitionMapper {

    /**
     * 插入流程定义
     */
    void insert(WfDefinition definition);

    /**
     * 根据ID查询
     */
    WfDefinition selectById(@Param("id") Long id);

    /**
     * 更新流程定义
     */
    void updateById(WfDefinition definition);

    /**
     * 删除流程定义
     */
    void deleteById(@Param("id") Long id);

    /**
     * 查询流程定义列表
     */
    List<WfDefinition> selectList(Map<String, Object> params);

    /**
     * 统计流程定义数量
     */
    long countList(Map<String, Object> params);
}
