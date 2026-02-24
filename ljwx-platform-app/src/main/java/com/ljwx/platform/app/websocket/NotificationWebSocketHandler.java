package com.ljwx.platform.app.websocket;

import com.ljwx.platform.security.jwt.JwtTokenProvider;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.net.URI;
import java.util.concurrent.ConcurrentHashMap;

/**
 * WebSocket 实时通知处理器。
 *
 * <p>连接流程：
 * <ol>
 *   <li>客户端连接时携带 query param {@code token}（JWT access token）</li>
 *   <li>验证 JWT；失败则以 {@link CloseStatus#POLICY_VIOLATION} 关闭连接</li>
 *   <li>成功则将 userId → session 存入映射表</li>
 * </ol>
 *
 * <p>其他 Service 可注入此 Bean 并调用 {@link #sendToUser(Long, String)}
 * 向指定用户推送消息。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationWebSocketHandler extends TextWebSocketHandler {

    private final JwtTokenProvider jwtTokenProvider;

    /** userId → WebSocketSession 映射，线程安全 */
    private final ConcurrentHashMap<Long, WebSocketSession> sessions = new ConcurrentHashMap<>();

    // ─────────────────────────────── 生命周期 ──────────────────────────────────

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long userId = authenticate(session);
        if (userId == null) {
            log.warn("[WS] JWT 验证失败，关闭连接 sessionId={}", session.getId());
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        sessions.put(userId, session);
        log.info("[WS] 用户 {} 已连接，sessionId={}", userId, session.getId());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.values().remove(session);
        log.info("[WS] 连接关闭 sessionId={} status={}", session.getId(), status);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // 当前版本服务端不处理客户端上行消息，仅做心跳 pong 回应
        log.debug("[WS] 收到消息 sessionId={} payload={}", session.getId(), message.getPayload());
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        log.error("[WS] 传输错误 sessionId={}", session.getId(), exception);
        sessions.values().remove(session);
    }

    // ─────────────────────────────── 推送 API ──────────────────────────────────

    /**
     * 向指定用户推送文本消息。
     *
     * @param userId  目标用户 ID
     * @param message 消息内容（JSON 字符串）
     */
    public void sendToUser(Long userId, String message) {
        WebSocketSession session = sessions.get(userId);
        if (session == null || !session.isOpen()) {
            log.debug("[WS] 用户 {} 不在线，消息丢弃", userId);
            return;
        }
        try {
            session.sendMessage(new TextMessage(message));
        } catch (IOException e) {
            log.error("[WS] 推送消息失败 userId={}", userId, e);
            sessions.remove(userId);
        }
    }

    // ─────────────────────────────── 内部方法 ──────────────────────────────────

    /**
     * 从 query param {@code token} 提取并验证 JWT，返回 userId；失败返回 null。
     */
    private Long authenticate(WebSocketSession session) {
        URI uri = session.getUri();
        if (uri == null) {
            return null;
        }
        String query = uri.getQuery();
        if (query == null || !query.contains("token=")) {
            return null;
        }
        String token = extractTokenParam(query);
        if (token == null || token.isBlank()) {
            return null;
        }
        try {
            Claims claims = jwtTokenProvider.parseToken(token);
            if (!jwtTokenProvider.isAccessToken(claims)) {
                return null;
            }
            return jwtTokenProvider.getUserId(claims);
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("[WS] JWT 解析失败: {}", e.getMessage());
            return null;
        }
    }

    private String extractTokenParam(String query) {
        for (String param : query.split("&")) {
            if (param.startsWith("token=")) {
                return param.substring("token=".length());
            }
        }
        return null;
    }
}
