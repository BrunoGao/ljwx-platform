package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.dto.MsgTemplateQueryDTO;
import com.ljwx.platform.app.vo.MsgTemplateVO;
import com.ljwx.platform.core.domain.MsgTemplate;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 消息模板Mapper
 *
 * @author LJWX Platform
 * @since Phase 50
 */
@Mapper
public interface MsgTemplateMapper {

    /**
     * 插入消息模板
     *
     * @param template 消息模板
     * @return 影响行数
     */
    int insert(MsgTemplate template);

    /**
     * 根据ID查询消息模板
     *
     * @param id 模板ID
     * @return 消息模板
     */
    MsgTemplate selectById(@Param("id") Long id);

    /**
     * 更新消息模板
     *
     * @param template 消息模板
     * @return 影响行数
     */
    int updateById(MsgTemplate template);

    /**
     * 根据ID删除消息模板（逻辑删除）
     *
     * @param id 模板ID
     * @return 影响行数
     */
    int deleteById(@Param("id") Long id);

    /**
     * 分页查询消息模板列表
     *
     * @param query 查询条件
     * @return 消息模板列表
     */
    List<MsgTemplateVO> selectTemplateList(@Param("query") MsgTemplateQueryDTO query);

    /**
     * 统计消息模板数量
     *
     * @param query 查询条件
     * @return 总数
     */
    long countTemplates(@Param("query") MsgTemplateQueryDTO query);

    /**
     * 根据模板编码查询
     *
     * @param templateCode 模板编码
     * @return 消息模板
     */
    MsgTemplate selectByTemplateCode(@Param("templateCode") String templateCode);
}
