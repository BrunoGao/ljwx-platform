package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.MsgUserInbox;
import com.ljwx.platform.app.vo.MsgUserInboxVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 用户收件箱Mapper
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Mapper
public interface MsgUserInboxMapper {

    /**
     * 插入收件箱消息
     *
     * @param inbox 收件箱消息
     * @return 影响行数
     */
    int insert(MsgUserInbox inbox);

    /**
     * 根据ID查询收件箱消息
     *
     * @param id 收件箱ID
     * @return 收件箱消息
     */
    MsgUserInbox selectById(@Param("id") Long id);

    /**
     * 更新收件箱消息
     *
     * @param inbox 收件箱消息
     * @return 影响行数
     */
    int updateById(MsgUserInbox inbox);

    /**
     * 删除收件箱消息
     *
     * @param id 收件箱ID
     * @return 影响行数
     */
    int deleteById(@Param("id") Long id);

    /**
     * 查询用户收件箱列表
     *
     * @param userId 用户ID
     * @param isRead 是否已读
     * @return 收件箱列表
     */
    List<MsgUserInboxVO> selectInboxList(
            @Param("userId") Long userId,
            @Param("isRead") Boolean isRead
    );

    /**
     * 根据ID查询收件箱详情
     *
     * @param id 收件箱ID
     * @return 收件箱详情
     */
    MsgUserInboxVO selectInboxById(@Param("id") Long id);
}
