package com.ljwx.platform.app.service;

import com.ljwx.platform.app.domain.entity.MsgRecord;
import com.ljwx.platform.app.domain.entity.MsgUserInbox;
import com.ljwx.platform.app.dto.MessageSendDTO;
import com.ljwx.platform.app.infra.mapper.MsgRecordMapper;
import com.ljwx.platform.app.infra.mapper.MsgUserInboxMapper;
import com.ljwx.platform.app.vo.MsgRecordVO;
import com.ljwx.platform.app.vo.MsgUserInboxVO;
import com.ljwx.platform.web.exception.BusinessException;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 消息服务
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MessageService {

    private final MsgRecordMapper msgRecordMapper;
    private final MsgUserInboxMapper msgUserInboxMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 发送消息
     *
     * @param dto 消息发送DTO
     * @return 消息记录ID
     */
    @Transactional(rollbackFor = Exception.class)
    public Long sendMessage(MessageSendDTO dto) {
        // 验证消息类型
        if (!isValidMessageType(dto.getMessageType())) {
            throw new BusinessException("无效的消息类型: " + dto.getMessageType());
        }

        // 验证接收地址
        if (("EMAIL".equals(dto.getMessageType()) || "SMS".equals(dto.getMessageType()))
                && (dto.getReceiverAddress() == null || dto.getReceiverAddress().isBlank())) {
            throw new BusinessException("邮件或短信发送必须提供接收地址");
        }

        // 创建消息记录
        MsgRecord record = new MsgRecord();
        record.setId(idGenerator.nextId());
        record.setTemplateId(dto.getTemplateId());
        record.setMessageType(dto.getMessageType());
        record.setReceiverId(dto.getReceiverId());
        record.setReceiverAddress(dto.getReceiverAddress());
        record.setSubject(dto.getSubject());
        record.setContent(dto.getContent());
        record.setSendStatus("PENDING");

        msgRecordMapper.insert(record);

        // 如果是站内信，写入收件箱
        if ("INBOX".equals(dto.getMessageType())) {
            MsgUserInbox inbox = new MsgUserInbox();
            inbox.setId(idGenerator.nextId());
            inbox.setUserId(dto.getReceiverId());
            inbox.setMessageId(record.getId());
            inbox.setTitle(dto.getSubject());
            inbox.setContent(dto.getContent());
            inbox.setIsRead(false);

            msgUserInboxMapper.insert(inbox);
        }

        // TODO: 异步处理邮件和短信发送
        log.info("消息发送请求已创建，消息ID: {}, 类型: {}", record.getId(), dto.getMessageType());

        return record.getId();
    }

    /**
     * 查询消息记录列表
     *
     * @param messageType 消息类型
     * @param sendStatus 发送状态
     * @param receiverId 接收用户ID
     * @return 消息记录列表
     */
    public List<MsgRecordVO> listRecords(String messageType, String sendStatus, Long receiverId) {
        return msgRecordMapper.selectRecordList(messageType, sendStatus, receiverId);
    }

    /**
     * 查询消息记录详情
     *
     * @param id 消息记录ID
     * @return 消息记录详情
     */
    public MsgRecordVO getRecordById(Long id) {
        MsgRecordVO record = msgRecordMapper.selectRecordById(id);
        if (record == null) {
            throw new BusinessException("消息记录不存在");
        }
        return record;
    }

    /**
     * 查询用户收件箱列表
     *
     * @param userId 用户ID
     * @param isRead 是否已读
     * @return 收件箱列表
     */
    public List<MsgUserInboxVO> listInbox(Long userId, Boolean isRead) {
        return msgUserInboxMapper.selectInboxList(userId, isRead);
    }

    /**
     * 标记消息已读
     *
     * @param id 收件箱消息ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void markAsRead(Long id) {
        MsgUserInbox inbox = msgUserInboxMapper.selectById(id);
        if (inbox == null) {
            throw new BusinessException("收件箱消息不存在");
        }

        if (Boolean.FALSE.equals(inbox.getIsRead())) {
            inbox.setIsRead(true);
            inbox.setReadTime(LocalDateTime.now());
            msgUserInboxMapper.updateById(inbox);
        }
    }

    /**
     * 删除收件箱消息
     *
     * @param id 收件箱消息ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void deleteInboxMessage(Long id) {
        MsgUserInbox inbox = msgUserInboxMapper.selectById(id);
        if (inbox == null) {
            throw new BusinessException("收件箱消息不存在");
        }

        msgUserInboxMapper.deleteById(id);
    }

    /**
     * 验证消息类型
     *
     * @param messageType 消息类型
     * @return 是否有效
     */
    private boolean isValidMessageType(String messageType) {
        return "INBOX".equals(messageType)
                || "EMAIL".equals(messageType)
                || "SMS".equals(messageType);
    }
}
