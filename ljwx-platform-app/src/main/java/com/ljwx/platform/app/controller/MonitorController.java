package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.domain.vo.JvmInfoVO;
import com.ljwx.platform.app.domain.vo.ServerInfoVO;
import com.ljwx.platform.core.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCache;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.File;
import java.lang.management.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 系统监控 Controller — 提供服务器、JVM、缓存实时信息。
 *
 * <p>路由前缀：{@code /api/v1/monitor}
 * <p>所有端点均需对应权限，无新增数据库迁移。
 */
@RestController
@RequestMapping("/api/v1/monitor")
@RequiredArgsConstructor
public class MonitorController {

    private final CacheManager cacheManager;

    /**
     * 获取服务器信息：CPU 使用率、内存、磁盘、OS 基本信息。
     */
    @PreAuthorize("hasAuthority('system:monitor:server')")
    @GetMapping("/server")
    public Result<ServerInfoVO> server() {
        ServerInfoVO vo = new ServerInfoVO();

        OperatingSystemMXBean osBean = ManagementFactory.getOperatingSystemMXBean();
        vo.setOsName(osBean.getName());
        vo.setOsArch(osBean.getArch());
        vo.setAvailableProcessors(osBean.getAvailableProcessors());

        // CPU 使用率（需要 com.sun.management 扩展接口）
        if (osBean instanceof com.sun.management.OperatingSystemMXBean sunOsBean) {
            double cpuLoad = sunOsBean.getCpuLoad();
            vo.setCpuUsage(cpuLoad >= 0 ? cpuLoad * 100 : -1);
        } else {
            vo.setCpuUsage(-1);
        }

        // JVM 进程内存（Runtime）
        Runtime runtime = Runtime.getRuntime();
        long memTotal = runtime.totalMemory();
        long memFree = runtime.freeMemory();
        vo.setMemoryTotal(memTotal);
        vo.setMemoryFree(memFree);
        vo.setMemoryUsed(memTotal - memFree);

        // 磁盘（根路径）
        File root = new File("/");
        vo.setDiskTotal(root.getTotalSpace());
        vo.setDiskFree(root.getFreeSpace());
        vo.setDiskUsed(root.getTotalSpace() - root.getFreeSpace());

        return Result.ok(vo);
    }

    /**
     * 获取 JVM 信息：堆内存、非堆内存、GC 统计、运行时信息。
     */
    @PreAuthorize("hasAuthority('system:monitor:jvm')")
    @GetMapping("/jvm")
    public Result<JvmInfoVO> jvm() {
        JvmInfoVO vo = new JvmInfoVO();

        MemoryMXBean memBean = ManagementFactory.getMemoryMXBean();
        MemoryUsage heap = memBean.getHeapMemoryUsage();
        MemoryUsage nonHeap = memBean.getNonHeapMemoryUsage();

        vo.setHeapMax(heap.getMax());
        vo.setHeapCommitted(heap.getCommitted());
        vo.setHeapUsed(heap.getUsed());
        vo.setNonHeapUsed(nonHeap.getUsed());

        RuntimeMXBean runtimeBean = ManagementFactory.getRuntimeMXBean();
        vo.setJvmVersion(runtimeBean.getVmVersion());
        vo.setJvmVendor(runtimeBean.getVmVendor());
        vo.setJvmName(runtimeBean.getVmName());
        vo.setUptime(runtimeBean.getUptime());

        List<JvmInfoVO.GcInfo> gcInfoList = new ArrayList<>();
        for (GarbageCollectorMXBean gcBean : ManagementFactory.getGarbageCollectorMXBeans()) {
            JvmInfoVO.GcInfo gcInfo = new JvmInfoVO.GcInfo();
            gcInfo.setName(gcBean.getName());
            gcInfo.setCollectionCount(gcBean.getCollectionCount());
            gcInfo.setCollectionTime(gcBean.getCollectionTime());
            gcInfoList.add(gcInfo);
        }
        vo.setGcInfoList(gcInfoList);

        return Result.ok(vo);
    }

    /**
     * 获取 Caffeine 缓存统计：缓存名称与估算条目数。
     */
    @PreAuthorize("hasAuthority('system:monitor:cache')")
    @GetMapping("/cache")
    public Result<List<Map<String, Object>>> cache() {
        List<Map<String, Object>> result = new ArrayList<>();
        for (String cacheName : cacheManager.getCacheNames()) {
            Cache cache = cacheManager.getCache(cacheName);
            Map<String, Object> info = new LinkedHashMap<>();
            info.put("name", cacheName);
            if (cache instanceof CaffeineCache caffeineCache) {
                info.put("estimatedSize", caffeineCache.getNativeCache().estimatedSize());
            } else {
                info.put("estimatedSize", -1);
            }
            result.add(info);
        }
        return Result.ok(result);
    }
}
