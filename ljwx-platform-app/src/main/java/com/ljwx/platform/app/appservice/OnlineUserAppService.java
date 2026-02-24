package com.ljwx.platform.app.appservice;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 在线用户应用服务。
 *
 * <p>基于 JWT 无状态架构，通过 Caffeine 缓存维护活跃 token 集合：
 * <ul>
 *   <li>key = jti（JWT ID，即 token 唯一标识）</li>
 *   <li>value = 用户名</li>
 *   <li>TTL = access token 过期时间（默认 30 分钟）</li>
 * </ul>
 *
 * <p>登录时注册 token，登出或强制下线时移除。
 */
@Service
public class OnlineUserAppService {

    /** 活跃 token 缓存：key=tokenId, value=username，TTL=30min */
    private final Cache<String, String> activeTokens = Caffeine.newBuilder()
            .expireAfterWrite(30, TimeUnit.MINUTES)
            .maximumSize(10_000)
            .build();

    /**
     * 注册活跃 token（登录时调用）。
     *
     * @param tokenId  JWT jti 或 sub+iat 组合唯一标识
     * @param username 登录用户名
     */
    public void register(String tokenId, String username) {
        activeTokens.put(tokenId, username);
    }

    /**
     * 移除 token（登出时调用）。
     */
    public void remove(String tokenId) {
        activeTokens.invalidate(tokenId);
    }

    /**
     * 检查 token 是否在黑名单（已被强制下线）。
     */
    public boolean isKickedOut(String tokenId) {
        return activeTokens.getIfPresent(tokenId) == null;
    }

    /**
     * 获取当前在线用户列表。
     *
     * @return 在线用户信息列表（tokenId → username）
     */
    public List<Map<String, String>> listOnlineUsers() {
        List<Map<String, String>> result = new ArrayList<>();
        activeTokens.asMap().forEach((tokenId, username) ->
                result.add(Map.of("tokenId", tokenId, "username", username)));
        return result;
    }

    /**
     * 强制下线指定 token。
     *
     * @param tokenId 要踢出的 token ID
     */
    public void kickout(String tokenId) {
        activeTokens.invalidate(tokenId);
    }
}
