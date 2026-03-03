package com.ljwx.platform.app.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ljwx.platform.app.domain.AiConversationLog;
import com.ljwx.platform.app.dto.ai.AiConversationLogQueryDTO;
import com.ljwx.platform.app.vo.ai.AiConversationLogVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * AI 对话日志 Mapper
 *
 * @author LJWX Platform
 */
@Mapper
public interface AiConversationLogMapper extends BaseMapper<AiConversationLog> {

    /**
     * 查询对话日志列表
     *
     * @param query 查询条件
     * @return 对话日志列表
     */
    List<AiConversationLogVO> selectLogList(@Param("query") AiConversationLogQueryDTO query);

    /**
     * 统计对话日志数量
     *
     * @param query 查询条件
     * @return 总数
     */
    long countLogs(@Param("query") AiConversationLogQueryDTO query);
}
