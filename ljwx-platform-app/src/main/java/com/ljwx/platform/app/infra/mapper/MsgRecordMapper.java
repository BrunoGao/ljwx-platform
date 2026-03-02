package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.domain.MsgRecord;
import com.ljwx.platform.app.vo.MsgRecordVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 消息记录Mapper
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Mapper
public interface MsgRecordMapper {

    /**
     * 插入消息记录
     *
     * @param record 消息记录
     * @return 影响行数
     */
    int insert(MsgRecord record);

    /**
     * 根据ID查询消息记录
     *
     * @param id 消息记录ID
     * @return 消息记录
     */
    MsgRecord selectById(@Param("id") Long id);

    /**
     * 更新消息记录
     *
     * @param record 消息记录
     * @return 影响行数
     */
    int updateById(MsgRecord record);

    /**
     * 查询消息记录列表
     *
     * @param messageType 消息类型
     * @param sendStatus 发送状态
     * @param receiverId 接收用户ID
     * @return 消息记录列表
     */
    List<MsgRecordVO> selectRecordList(
            @Param("messageType") String messageType,
            @Param("sendStatus") String sendStatus,
            @Param("receiverId") Long receiverId
    );

    /**
     * 根据ID查询消息记录详情
     *
     * @param id 消息记录ID
     * @return 消息记录详情
     */
    MsgRecordVO selectRecordById(@Param("id") Long id);
}
