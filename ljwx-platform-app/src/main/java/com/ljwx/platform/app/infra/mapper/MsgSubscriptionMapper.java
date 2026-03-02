package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.domain.MsgSubscription;
import com.ljwx.platform.app.dto.MsgSubscriptionQueryDTO;
import com.ljwx.platform.app.vo.MsgSubscriptionVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 消息订阅 Mapper
 *
 * @author LJWX Platform
 * @since Phase 52
 */
@Mapper
public interface MsgSubscriptionMapper {

    /**
     * 插入订阅
     *
     * @param subscription 订阅信息
     * @return 影响行数
     */
    int insert(MsgSubscription subscription);

    /**
     * 根据 ID 更新订阅
     *
     * @param subscription 订阅信息
     * @return 影响行数
     */
    int updateById(MsgSubscription subscription);

    /**
     * 根据 ID 删除订阅（软删除）
     *
     * @param id 订阅 ID
     * @return 影响行数
     */
    int deleteById(Long id);

    /**
     * 根据 ID 查询订阅
     *
     * @param id 订阅 ID
     * @return 订阅信息
     */
    MsgSubscription selectById(Long id);

    /**
     * 统计订阅数量
     *
     * @param subscription 查询条件
     * @return 订阅数量
     */
    long selectCount(MsgSubscription subscription);

    /**
     * 查询订阅列表
     *
     * @param query 查询条件
     * @return 订阅列表
     */
    List<MsgSubscriptionVO> selectSubscriptionList(@Param("query") MsgSubscriptionQueryDTO query);

    /**
     * 统计订阅数量
     *
     * @param query 查询条件
     * @return 订阅数量
     */
    long countSubscriptions(@Param("query") MsgSubscriptionQueryDTO query);

    /**
     * 根据 ID 查询订阅详情
     *
     * @param id 订阅 ID
     * @return 订阅详情
     */
    MsgSubscriptionVO selectSubscriptionById(@Param("id") Long id);
}
