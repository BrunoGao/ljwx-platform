package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.ai.AiChatDTO;
import com.ljwx.platform.app.dto.ai.AiConversationLogQueryDTO;
import com.ljwx.platform.app.service.AiChatAppService;
import com.ljwx.platform.app.vo.ai.AiChatVO;
import com.ljwx.platform.app.vo.ai.AiConversationLogVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * AI 对话控制器
 *
 * @author LJWX Platform
 */
@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
public class AiChatController {

    private final AiChatAppService aiChatAppService;

    /**
     * 发送消息
     *
     * @param dto 对话请求
     * @return 对话响应
     */
    @PreAuthorize("hasAuthority('system:ai:chat')")
    @PostMapping("/chat")
    public Result<AiChatVO> chat(@Valid @RequestBody AiChatDTO dto) {
        return Result.ok(aiChatAppService.chat(dto));
    }

    /**
     * 查询对话历史
     *
     * @param query 查询条件
     * @return 对话历史分页结果
     */
    @PreAuthorize("hasAuthority('system:ai:log:list')")
    @GetMapping("/conversations")
    public Result<PageResult<AiConversationLogVO>> conversations(AiConversationLogQueryDTO query) {
        return Result.ok(aiChatAppService.listConversations(query));
    }
}
