package com.ljwx.platform.security.blacklist;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.stereotype.Service;

import java.time.Duration;

/**
 * Token 黑名单服务（基于 Caffeine 本地缓存）。
 *
 * <p>登出时将 token 的 jti 加入黑名单，{@link com.ljwx.platform.security.filter.JwtAuthenticationFilter}
 * 在每次请求时检查 jti 是否在黑名单中。
 *
 * <p>value 存储过期时间戳（ms），避免已过期的黑名单条目误判。
 * 缓存条目最长保留 8 天（略长于 refresh token 最大有效期）。
 */
@Service
public class TokenBlacklistService {

    private final Cache<String, Long> blacklist = Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofDays(8))
            .maximumSize(10_000)
            .build();

    /**
     * 将 jti 加入黑名单。
     *
     * @param jti              JWT ID（token 唯一标识）
     * @param remainingSeconds token 剩余有效秒数
     */
    public void addToBlacklist(String jti, long remainingSeconds) {
        if (remainingSeconds > 0) {
            blacklist.put(jti, System.currentTimeMillis() + remainingSeconds * 1000L);
        }
    }

    /**
     * 检查 jti 是否在黑名单中且尚未过期。
     */
    public boolean isBlacklisted(String jti) {
        Long expiry = blacklist.getIfPresent(jti);
        return expiry != null && System.currentTimeMillis() < expiry;
    }
}
