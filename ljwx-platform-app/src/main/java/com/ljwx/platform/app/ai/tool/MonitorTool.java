package com.ljwx.platform.app.ai.tool;

import com.github.benmanes.caffeine.cache.stats.CacheStats;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCache;
import org.springframework.stereotype.Component;

import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.OperatingSystemMXBean;
import java.util.HashMap;
import java.util.Map;

/**
 * 监控工具 - 提供系统状态查询
 *
 * @author LJWX Platform
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MonitorTool {

    private final CacheManager cacheManager;

    /**
     * 获取服务器状态
     * 权限约束：仅 system:monitor:server
     *
     * @return 服务器状态信息
     */
    public Map<String, Object> getServerStatus() {
        Map<String, Object> status = new HashMap<>();

        // JVM 信息
        Runtime runtime = Runtime.getRuntime();
        long totalMemory = runtime.totalMemory();
        long freeMemory = runtime.freeMemory();
        long usedMemory = totalMemory - freeMemory;
        long maxMemory = runtime.maxMemory();

        Map<String, Object> jvm = new HashMap<>();
        jvm.put("totalMemoryMB", totalMemory / 1024 / 1024);
        jvm.put("usedMemoryMB", usedMemory / 1024 / 1024);
        jvm.put("freeMemoryMB", freeMemory / 1024 / 1024);
        jvm.put("maxMemoryMB", maxMemory / 1024 / 1024);
        jvm.put("memoryUsagePercent", (double) usedMemory / maxMemory * 100);
        status.put("jvm", jvm);

        // CPU 信息
        OperatingSystemMXBean osBean = ManagementFactory.getOperatingSystemMXBean();
        Map<String, Object> cpu = new HashMap<>();
        cpu.put("availableProcessors", osBean.getAvailableProcessors());
        cpu.put("systemLoadAverage", osBean.getSystemLoadAverage());
        status.put("cpu", cpu);

        // 内存信息
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
        Map<String, Object> memory = new HashMap<>();
        memory.put("heapMemoryUsageMB", memoryBean.getHeapMemoryUsage().getUsed() / 1024 / 1024);
        memory.put("nonHeapMemoryUsageMB", memoryBean.getNonHeapMemoryUsage().getUsed() / 1024 / 1024);
        status.put("memory", memory);

        return status;
    }

    /**
     * 获取缓存统计信息
     * 权限约束：仅 system:monitor:cache
     *
     * @return 缓存统计信息
     */
    public Map<String, Object> getCacheStats() {
        Map<String, Object> stats = new HashMap<>();
        long totalRequests = 0L;
        long totalHits = 0L;
        long totalMisses = 0L;
        long cacheSize = 0L;

        for (String cacheName : cacheManager.getCacheNames()) {
            Cache cache = cacheManager.getCache(cacheName);
            if (cache instanceof CaffeineCache caffeineCache) {
                cacheSize += caffeineCache.getNativeCache().estimatedSize();
                CacheStats cacheStats = caffeineCache.getNativeCache().stats();
                totalRequests += cacheStats.requestCount();
                totalHits += cacheStats.hitCount();
                totalMisses += cacheStats.missCount();
            }
        }

        double hitRate = totalRequests == 0 ? 0D : (double) totalHits / totalRequests;
        double missRate = totalRequests == 0 ? 0D : (double) totalMisses / totalRequests;

        stats.put("hitRate", hitRate);
        stats.put("missRate", missRate);
        stats.put("totalRequests", totalRequests);
        stats.put("cacheSize", cacheSize);
        stats.put("cacheCount", cacheManager.getCacheNames().size());
        return stats;
    }
}
