package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.MessageSendDTO;
import com.ljwx.platform.app.service.MessageService;
import com.ljwx.platform.app.vo.MsgRecordVO;
import com.ljwx.platform.app.vo.MsgUserInboxVO;
import com.ljwx.platform.core.result.Result;
import com.ljwx.platform.security.util.SecurityUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 消息控制器
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@RestController
@RequestMapping("/api/v1/messages")
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    /**
     * 发送消息
     *
     * @param dto 消息发送DTO
     * @return 消息记录ID
     */
    @PreAuthorize("hasAuthority('system:message:send')")
    @PostMapping("/send")
    public Result<Long> sendMessage(@Valid @RequestBody MessageSendDTO dto) {
        Long messageId = messageService.sendMessage(dto);
        return Result.ok(messageId);
    }

    /**
     * 查询消息记录列表
     *
     * @param messageType 消息类型
     * @param sendStatus 发送状态
     * @param receiverId 接收用户ID
     * @return 消息记录列表
     */
    @PreAuthorize("hasAuthority('system:message:record:list')")
    @GetMapping("/records")
    public Result<List<MsgRecordVO>> listRecords(
            @RequestParam(required = false) String messageType,
            @RequestParam(required = false) String sendStatus,
            @RequestParam(required = false) Long receiverId) {
        List<MsgRecordVO> records = messageService.listRecords(messageType, sendStatus, receiverId);
        return Result.ok(records);
    }

    /**
     * 查询消息记录详情
     *
     * @param id 消息记录ID
     * @return 消息记录详情
     */
    @PreAuthorize("hasAuthority('system:message:record:query')")
    @GetMapping("/records/{id}")
    public Result<MsgRecordVO> getRecord(@PathVariable Long id) {
        MsgRecordVO record = messageService.getRecordById(id);
        return Result.ok(record);
    }

    /**
     * 查询用户收件箱
     *
     * @param isRead 是否已读
     * @return 收件箱列表
     */
    @PreAuthorize("hasAuthority('system:message:inbox:list')")
    @GetMapping("/inbox")
    public Result<List<MsgUserInboxVO>> listInbox(
            @RequestParam(required = false) Boolean isRead) {
        Long userId = SecurityUtils.getCurrentUserId();
        List<MsgUserInboxVO> inbox = messageService.listInbox(userId, isRead);
        return Result.ok(inbox);
    }

    /**
     * 标记消息已读
     *
     * @param id 收件箱消息ID
     * @return 成功响应
     */
    @PreAuthorize("hasAuthority('system:message:inbox:read')")
    @PutMapping("/inbox/{id}/read")
    public Result<Void> markAsRead(@PathVariable Long id) {
        messageService.markAsRead(id);
        return Result.ok();
    }

    /**
     * 删除收件箱消息
     *
     * @param id 收件箱消息ID
     * @return 成功响应
     */
    @PreAuthorize("hasAuthority('system:message:inbox:delete')")
    @DeleteMapping("/inbox/{id}")
    public Result<Void> deleteInboxMessage(@PathVariable Long id) {
        messageService.deleteInboxMessage(id);
        return Result.ok();
    }
}
