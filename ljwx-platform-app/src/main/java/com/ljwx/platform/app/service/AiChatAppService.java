package com.ljwx.platform.app.service;

import com.ljwx.platform.app.ai.tool.JobQueryTool;
import com.ljwx.platform.app.ai.tool.LogQueryTool;
import com.ljwx.platform.app.ai.tool.MonitorTool;
import com.ljwx.platform.app.ai.tool.OnlineUserTool;
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

import java.time.LocalDateTime;
import java.util.*;

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
    private final OnlineUserTool onlineUserTool;
    private final MonitorTool monitorTool;
    private final JobQueryTool jobQueryTool;
    private final LogQueryTool logQueryTool;

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
        Long tenantId = CurrentTenantHolder.get();
        AiConfig config = configService.getActiveConfig(tenantId);

        String sessionId = dto.getSessionId();
        if (sessionId == null || sessionId.isBlank()) {
            sessionId = UUID.randomUUID().toString();
        }

        long start = System.currentTimeMillis();
        List<Map<String, Object>> toolCalls = new ArrayList<>();
        String answer = resolveAnswer(dto.getMessage(), toolCalls);
        long durationMs = System.currentTimeMillis() - start;
        int tokensUsed = estimateTokens(dto.getMessage(), answer, toolCalls);

        saveConversationLog(sessionId, dto.getMessage(), answer, toolCalls, tokensUsed, durationMs, config.getModelName());

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

        list.forEach(vo -> {
            AiConversationLog entity = logMapper.selectById(vo.getId());
            if (entity == null || entity.getToolCalls() == null) {
                vo.setToolCallSummary(List.of());
                return;
            }
            List<String> toolNames = entity.getToolCalls().stream()
                    .map(call -> String.valueOf(call.getOrDefault("name", "")))
                    .filter(name -> !name.isBlank())
                    .distinct()
                    .toList();
            vo.setToolCallSummary(toolNames);
        });

        return new PageResult<>(list, total);
    }

    private String resolveAnswer(String message, List<Map<String, Object>> toolCalls) {
        String trimmedMessage = message == null ? "" : message.trim();
        String lowerCaseMessage = trimmedMessage.toLowerCase(Locale.ROOT);
        List<String> sections = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        if (containsAny(lowerCaseMessage, "在线", "online")) {
            Map<String, Object> result = onlineUserTool.getOnlineUserCount();
            toolCalls.add(buildToolCall("onlineUser.getOnlineUserCount", Map.of(), result));
            sections.add("在线用户数: " + result.get("onlineCount"));
        }

        if (containsAny(lowerCaseMessage, "缓存", "cache")) {
            Map<String, Object> result = monitorTool.getCacheStats();
            toolCalls.add(buildToolCall("monitor.getCacheStats", Map.of(), result));
            sections.add(String.format(Locale.ROOT,
                    "缓存命中率: %.2f%%, 当前缓存条目: %s",
                    toPercentage(result.get("hitRate")),
                    result.get("cacheSize")));
        }

        if (containsAny(lowerCaseMessage, "监控", "cpu", "内存", "服务器", "jvm")) {
            Map<String, Object> result = monitorTool.getServerStatus();
            toolCalls.add(buildToolCall("monitor.getServerStatus", Map.of(), result));
            sections.add(formatServerStatus(result));
        }

        if (containsAny(lowerCaseMessage, "任务", "job", "定时")) {
            Long jobId = extractFirstLong(trimmedMessage);
            if (containsAny(lowerCaseMessage, "日志", "执行") && jobId != null) {
                Map<String, Object> result = jobQueryTool.getJobLogs(jobId, 5);
                toolCalls.add(buildToolCall("job.getJobLogs", Map.of("jobId", jobId, "limit", 5), result));
                sections.add(formatJobLogs(result));
            } else {
                Map<String, Object> result = jobQueryTool.listScheduledJobs();
                toolCalls.add(buildToolCall("job.listScheduledJobs", Map.of(), result));
                sections.add(formatJobSummary(result));
            }
        }

        if (containsAny(lowerCaseMessage, "操作日志", "审计日志")
                || (containsAny(lowerCaseMessage, "日志") && containsAny(lowerCaseMessage, "操作"))) {
            Map<String, Object> result = logQueryTool.queryOperationLogs(now.minusDays(7), now, null, null, 5);
            toolCalls.add(buildToolCall("log.queryOperationLogs",
                    Map.of("startTime", now.minusDays(7), "endTime", now, "limit", 5), result));
            sections.add(formatOperationLogs(result));
        }

        if (containsAny(lowerCaseMessage, "登录日志", "登录记录", "login")) {
            Map<String, Object> result = logQueryTool.queryLoginLogs(now.minusDays(7), now, null, 5);
            toolCalls.add(buildToolCall("log.queryLoginLogs",
                    Map.of("startTime", now.minusDays(7), "endTime", now, "limit", 5), result));
            sections.add(formatLoginLogs(result));
        }

        if (sections.isEmpty()) {
            sections.add("当前助手支持查询在线用户、服务器监控、缓存状态、定时任务、操作日志和登录日志。");
            sections.add("可直接提问，例如：当前在线用户数、最近 5 条操作日志、任务 123 的执行日志。");
        }

        return String.join("\n", sections);
    }

    private Map<String, Object> buildToolCall(String name, Map<String, Object> arguments, Map<String, Object> result) {
        Map<String, Object> toolCall = new LinkedHashMap<>();
        toolCall.put("name", name);
        toolCall.put("arguments", arguments);
        toolCall.put("result", result);
        return toolCall;
    }

    private String formatServerStatus(Map<String, Object> result) {
        Map<String, Object> cpu = asMap(result.get("cpu"));
        Map<String, Object> jvm = asMap(result.get("jvm"));
        Map<String, Object> memory = asMap(result.get("memory"));
        return String.format(Locale.ROOT,
                "CPU 核数: %s, 系统负载: %s, JVM 内存使用: %s MB / %s MB, 非堆内存: %s MB",
                cpu.getOrDefault("availableProcessors", 0),
                cpu.getOrDefault("systemLoadAverage", 0),
                jvm.getOrDefault("usedMemoryMB", 0),
                jvm.getOrDefault("maxMemoryMB", 0),
                memory.getOrDefault("nonHeapMemoryUsageMB", 0));
    }

    private String formatJobSummary(Map<String, Object> result) {
        List<?> jobs = asList(result.get("jobs"));
        if (jobs.isEmpty()) {
            return "当前没有可查询的定时任务。";
        }
        Object first = jobs.get(0);
        return "任务总数: " + result.get("total") + "，最近一条: " + first;
    }

    private String formatJobLogs(Map<String, Object> result) {
        List<?> logs = asList(result.get("logs"));
        if (logs.isEmpty()) {
            return "没有查到该任务的执行日志。";
        }
        return "任务日志共 " + result.get("total") + " 条，最近一条: " + logs.get(0);
    }

    private String formatOperationLogs(Map<String, Object> result) {
        List<?> logs = asList(result.get("logs"));
        if (logs.isEmpty()) {
            return "最近 7 天没有查询到操作日志。";
        }
        return "最近 7 天操作日志 " + result.get("total") + " 条，最新记录: " + logs.get(0);
    }

    private String formatLoginLogs(Map<String, Object> result) {
        List<?> logs = asList(result.get("logs"));
        if (logs.isEmpty()) {
            return "最近 7 天没有查询到登录日志。";
        }
        return "最近 7 天登录日志 " + result.get("total") + " 条，最新记录: " + logs.get(0);
    }

    private double toPercentage(Object ratio) {
        if (!(ratio instanceof Number number)) {
            return 0D;
        }
        return number.doubleValue() * 100D;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> asMap(Object value) {
        if (value instanceof Map<?, ?> map) {
            return (Map<String, Object>) map;
        }
        return Map.of();
    }

    private List<?> asList(Object value) {
        if (value instanceof List<?> list) {
            return list;
        }
        return List.of();
    }

    private boolean containsAny(String source, String... keywords) {
        for (String keyword : keywords) {
            if (source.contains(keyword.toLowerCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }

    private Long extractFirstLong(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        for (String token : text.split("[^0-9]+")) {
            if (!token.isBlank()) {
                try {
                    return Long.parseLong(token);
                } catch (NumberFormatException ignored) {
                    return null;
                }
            }
        }
        return null;
    }

    private int estimateTokens(String question, String answer, List<Map<String, Object>> toolCalls) {
        int contentLength = (question == null ? 0 : question.length())
                + (answer == null ? 0 : answer.length())
                + toolCalls.toString().length();
        return Math.max(contentLength / 4, 1);
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
