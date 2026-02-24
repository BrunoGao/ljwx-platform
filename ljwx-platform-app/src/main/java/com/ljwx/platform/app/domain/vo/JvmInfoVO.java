package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.util.List;

/**
 * JVM 信息 VO — 堆内存、非堆内存、GC 统计、运行时信息。
 *
 * <p>由 {@link com.ljwx.platform.app.controller.MonitorController#jvm()} 填充，
 * 使用 {@code java.lang.management.ManagementFactory} 获取数据。
 */
@Data
public class JvmInfoVO {

    /** 堆内存最大值（字节） */
    private long heapMax;

    /** 堆内存已提交量（字节） */
    private long heapCommitted;

    /** 堆内存已用量（字节） */
    private long heapUsed;

    /** 非堆内存已用量（字节） */
    private long nonHeapUsed;

    /** JVM 版本 */
    private String jvmVersion;

    /** JVM 供应商 */
    private String jvmVendor;

    /** JVM 名称 */
    private String jvmName;

    /** JVM 启动时长（毫秒） */
    private long uptime;

    /** GC 收集器信息列表 */
    private List<GcInfo> gcInfoList;

    /**
     * 单个 GC 收集器的统计信息。
     */
    @Data
    public static class GcInfo {

        /** GC 收集器名称（如 G1 Young Generation） */
        private String name;

        /** 累计 GC 次数 */
        private long collectionCount;

        /** 累计 GC 耗时（毫秒） */
        private long collectionTime;
    }
}
