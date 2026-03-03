package com.ljwx.platform.app.service;

import com.ljwx.platform.app.domain.AiConfig;
import com.ljwx.platform.app.domain.AiConversationLog;
import com.ljwx.platform.app.dto.ai.AiChatDTO;
import com.ljwx.platform.app.dto.ai.AiConversationLogQueryDTO;
import com.ljwx.platform.app.mapper.AiConversationLogMapper;
import com.ljwx.platform.app.vo.ai.AiChatVO;
import com.ljwx.platform.app.vo.ai.AiConversationLogVO;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * AI 对话服务
 *
 * @author LJWX Platform
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AiChatAppService {

    private final AiConfigAppService configService;
    private final AiConversationLogMapper logMapper;

    /**
     * 发送消息并获取 AI 回答
     * 安全约束：
     * 1. Agent 使用只读 Tool，无写操作权限
     * 2. 每次对话全量写入 sys_ai_conversation_log（含 tool_calls JSONB）
     * 3. API Key 从 sys_ai_config 动态加载，不硬编码
     *
     * @param dto 对话请求
     * @return 对话响应
     */
    @Transactional
    public AiChatVO chat(AiChatDTO dto) {
        // 1. 加载 AI 配置
        Long tenantId = CurrentTenantHolder.get();
        AiConfig config = configService.getActiveConfig(tenantId);

        // 2. 生成或使用会话 ID
        String sessionId = dto.getSessionId();
        if (sessionId == null || sessionId.isBlank()) {
            sessionId = UUID.randomUUID().toString();
        }

        // 3. 调用 AI 模型（简化实现：返回占位响应）
        // 实际应使用 Spring AI ChatModel
        long start = System.currentTimeMillis();
        String answer = "这是 AI 助手的占位响应。实际应调用 Spring AI ChatModel。";
        List<Map<String, Object>> toolCalls = new ArrayList<>();
        int tokensUsed = 100;
        long durationMs = System.currentTimeMillis() - start;

        // 4. 写入审计日志
        saveConversationLog(sessionId, dto.getMessage(), answer, toolCalls, tokensUsed, durationMs, config.getModelName());

        // 5. 构建响应
        return AiChatVO.builder()
                .sessionId(sessionId)
                .answer(answer)
                .toolCalls(toolCalls)
                .tokensUsed(tokensUsed)
                .durationMs(durationMs)
                .build();
    }

    /**
     * 查询对话历史
     *
     * @param query 查询条件
     * @return 对话历史分页结果
     */
    public PageResult<AiConversationLogVO> listConversations(AiConversationLogQueryDTO query) {
        List<AiConversationLogVO> list = logMapper.selectLogList(query);
        long total = logMapper.countLogs(query);

        // 处理 toolCallSummary（从 JSONB 提取名称）
        list.forEach(vo -> {
            // 简化实现：返回空列表
            vo.setToolCallSummary(List.of());
        });

        return new PageResult<>(list, total);
    }

    /**
     * 保存对话日志
     *
     * @param sessionId  会话 ID
     * @param question   用户提问
     * @param answer     AI 回答
     * @param toolCalls  Tool 调用链
     * @param tokensUsed 消耗 Token 数
     * @param durationMs 响应耗时
     * @param modelName  模型名称
     */
    private void saveConversationLog(String sessionId, String question, String answer,
                                       List<Map<String, Object>> toolCalls, int tokensUsed,
                                       long durationMs, String modelName) {
        try {
            AiConversationLog log = new AiConversationLog();
            log.setUserId(CurrentUserHolder.get());
            log.setSessionId(sessionId);
            log.setQuestion(question);
            log.setAnswer(answer);
            log.setToolCalls(toolCalls);
            log.setTokensUsed(tokensUsed);
            log.setDurationMs(durationMs);
            log.setModelName(modelName);

            logMapper.insert(log);
        } catch (Exception e) {
            // 降级策略：写日志失败不阻断对话响应
            log.error("保存 AI 对话日志失败", e);
        }
    }
}
