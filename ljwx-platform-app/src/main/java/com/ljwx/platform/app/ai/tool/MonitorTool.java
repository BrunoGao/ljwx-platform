package com.ljwx.platform.app.ai.tool;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
        // 简化实现：返回占位数据
        // 实际应从 CacheManager 获取 Caffeine 缓存统计
        stats.put("hitRate", 0.85);
        stats.put("missRate", 0.15);
        stats.put("totalRequests", 10000);
        stats.put("cacheSize", 500);
        return stats;
    }
}

