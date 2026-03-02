package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.domain.WfTask;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 流程任务 Mapper
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Mapper
public interface WfTaskMapper {

    /**
     * 插入任务
     */
    void insert(WfTask task);

    /**
     * 根据ID查询
     */
    WfTask selectById(@Param("id") Long id);

    /**
     * 更新任务
     */
    void updateById(WfTask task);

    /**
     * 删除任务
     */
    void deleteById(@Param("id") Long id);

    /**
     * 查询任务列表
     */
    List<WfTask> selectList(Map<String, Object> params);

    /**
     * 统计任务数量
     */
    long countList(Map<String, Object> params);
}
