package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.domain.WfHistory;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 流程历史 Mapper
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Mapper
public interface WfHistoryMapper {

    /**
     * 插入历史记录
     */
    void insert(WfHistory history);

    /**
     * 根据ID查询
     */
    WfHistory selectById(@Param("id") Long id);

    /**
     * 更新历史记录
     */
    void updateById(WfHistory history);

    /**
     * 删除历史记录
     */
    void deleteById(@Param("id") Long id);

    /**
     * 查询历史记录列表
     */
    List<WfHistory> selectList(Map<String, Object> params);

    /**
     * 统计历史记录数量
     */
    long countList(Map<String, Object> params);
}
