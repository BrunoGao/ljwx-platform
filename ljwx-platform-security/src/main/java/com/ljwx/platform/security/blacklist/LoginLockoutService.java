package com.ljwx.platform.security.blacklist;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 登录失败锁定服务（基于 Caffeine 本地缓存）。
 *
 * <p>连续登录失败 {@value #MAX_FAILURES} 次后锁定账号 {@value #LOCKOUT_MINUTES} 分钟。
 * 登录成功后清除失败记录。
 */
@Service
public class LoginLockoutService {

    private static final int MAX_FAILURES = 5;
    private static final int LOCKOUT_MINUTES = 30;

    /** 失败计数缓存：key=username，value=失败次数；30 分钟无新失败则自动清除。 */
    private final Cache<String, AtomicInteger> failureCache = Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(LOCKOUT_MINUTES))
            .build();

    /** 锁定缓存：key=username，value=true；30 分钟后自动解锁。 */
    private final Cache<String, Boolean> lockoutCache = Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(LOCKOUT_MINUTES))
            .build();

    /**
     * 记录一次登录失败。失败次数达到阈值时自动锁定账号。
     */
    public void recordFailure(String username) {
        AtomicInteger count = failureCache.get(username, k -> new AtomicInteger(0));
        int failures = count.incrementAndGet();
        if (failures >= MAX_FAILURES) {
            lockoutCache.put(username, Boolean.TRUE);
        }
    }

    /**
     * 检查账号是否被锁定。
     */
    public boolean isLocked(String username) {
        return lockoutCache.getIfPresent(username) != null;
    }

    /**
     * 登录成功后清除失败记录和锁定状态。
     */
    public void clearFailure(String username) {
        failureCache.invalidate(username);
        lockoutCache.invalidate(username);
    }
}
