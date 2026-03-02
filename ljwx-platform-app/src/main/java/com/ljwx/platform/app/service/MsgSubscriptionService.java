package com.ljwx.platform.app.service;

import com.ljwx.platform.app.domain.entity.MsgSubscription;
import com.ljwx.platform.app.dto.MsgSubscriptionDTO;
import com.ljwx.platform.app.dto.MsgSubscriptionQueryDTO;
import com.ljwx.platform.app.infra.mapper.MsgSubscriptionMapper;
import com.ljwx.platform.app.vo.MsgSubscriptionVO;
import com.ljwx.platform.web.exception.BusinessException;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 消息订阅服务
 *
 * @author LJWX Platform
 * @since Phase 52
 */
@Service
@RequiredArgsConstructor
public class MsgSubscriptionService {

    private final MsgSubscriptionMapper msgSubscriptionMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 创建订阅
     *
     * @param dto 订阅信息
     * @return 订阅 ID
     */
    @Transactional(rollbackFor = Exception.class)
    public Long create(MsgSubscriptionDTO dto) {
        // 检查是否已存在相同订阅
        MsgSubscription query = new MsgSubscription();
        query.setUserId(dto.getUserId());
        query.setTemplateId(dto.getTemplateId());
        query.setChannel(dto.getChannel());

        long count = msgSubscriptionMapper.selectCount(query);
        if (count > 0) {
            throw new BusinessException("该用户已订阅此模板的该渠道");
        }

        MsgSubscription subscription = new MsgSubscription();
        subscription.setId(idGenerator.nextId());
        subscription.setUserId(dto.getUserId());
        subscription.setTemplateId(dto.getTemplateId());
        subscription.setChannel(dto.getChannel());
        subscription.setStatus(dto.getStatus());
        subscription.setPreference(dto.getPreference());
        subscription.setTenantId(0L);
        subscription.setCreatedBy(0L);
        subscription.setCreatedTime(LocalDateTime.now());
        subscription.setUpdatedBy(0L);
        subscription.setUpdatedTime(LocalDateTime.now());
        subscription.setDeleted(false);
        subscription.setVersion(1);

        msgSubscriptionMapper.insert(subscription);
        return subscription.getId();
    }

    /**
     * 更新订阅
     *
     * @param id  订阅 ID
     * @param dto 订阅信息
     */
    @Transactional(rollbackFor = Exception.class)
    public void update(Long id, MsgSubscriptionDTO dto) {
        MsgSubscription subscription = msgSubscriptionMapper.selectById(id);
        if (subscription == null || subscription.getDeleted()) {
            throw new BusinessException("订阅不存在");
        }

        // 如果修改了用户、模板或渠道，需要检查唯一性
        if (!subscription.getUserId().equals(dto.getUserId())
                || !subscription.getTemplateId().equals(dto.getTemplateId())
                || !subscription.getChannel().equals(dto.getChannel())) {

            MsgSubscription query = new MsgSubscription();
            query.setUserId(dto.getUserId());
            query.setTemplateId(dto.getTemplateId());
            query.setChannel(dto.getChannel());

            long count = msgSubscriptionMapper.selectCount(query);
            // 需要排除当前记录
            if (count > 0) {
                // 简化处理：如果存在记录，检查是否是当前记录
                throw new BusinessException("该用户已订阅此模板的该渠道");
            }
        }

        subscription.setUserId(dto.getUserId());
        subscription.setTemplateId(dto.getTemplateId());
        subscription.setChannel(dto.getChannel());
        subscription.setStatus(dto.getStatus());
        subscription.setPreference(dto.getPreference());
        subscription.setUpdatedTime(LocalDateTime.now());

        msgSubscriptionMapper.updateById(subscription);
    }

    /**
     * 删除订阅
     *
     * @param id 订阅 ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        MsgSubscription subscription = msgSubscriptionMapper.selectById(id);
        if (subscription == null || subscription.getDeleted()) {
            throw new BusinessException("订阅不存在");
        }

        msgSubscriptionMapper.deleteById(id);
    }

    /**
     * 查询订阅详情
     *
     * @param id 订阅 ID
     * @return 订阅详情
     */
    public MsgSubscriptionVO getById(Long id) {
        MsgSubscriptionVO vo = msgSubscriptionMapper.selectSubscriptionById(id);
        if (vo == null) {
            throw new BusinessException("订阅不存在");
        }
        return vo;
    }

    /**
     * 分页查询订阅列表
     *
     * @param query 查询条件
     * @return 分页结果
     */
    public PageResult<MsgSubscriptionVO> list(MsgSubscriptionQueryDTO query) {
        List<MsgSubscriptionVO> list = msgSubscriptionMapper.selectSubscriptionList(query);
        long total = msgSubscriptionMapper.countSubscriptions(query);
        return new PageResult<>(list, total);
    }

    /**
     * 更新订阅状态
     *
     * @param id     订阅 ID
     * @param status 新状态
     */
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long id, String status) {
        MsgSubscription subscription = msgSubscriptionMapper.selectById(id);
        if (subscription == null || subscription.getDeleted()) {
            throw new BusinessException("订阅不存在");
        }

        subscription.setStatus(status);
        subscription.setUpdatedTime(LocalDateTime.now());
        msgSubscriptionMapper.updateById(subscription);
    }
}
