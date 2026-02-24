package com.ljwx.platform.app.domain.vo;

import lombok.Data;

/**
 * 服务器信息 VO — CPU、内存、磁盘、OS 基本信息。
 *
 * <p>由 {@link com.ljwx.platform.app.controller.MonitorController#server()} 填充，
 * 使用 {@code java.lang.management.ManagementFactory} 和 {@code java.io.File} 获取数据，
 * 无需额外依赖。
 */
@Data
public class ServerInfoVO {

    /** CPU 使用率（百分比，0–100），-1 表示不可用 */
    private double cpuUsage;

    /** 可用处理器核心数 */
    private int availableProcessors;

    /** 操作系统名称 */
    private String osName;

    /** 操作系统架构 */
    private String osArch;

    /** JVM 进程内存总量（字节） */
    private long memoryTotal;

    /** JVM 进程已用内存（字节） */
    private long memoryUsed;

    /** JVM 进程空闲内存（字节） */
    private long memoryFree;

    /** 根磁盘总空间（字节） */
    private long diskTotal;

    /** 根磁盘已用空间（字节） */
    private long diskUsed;

    /** 根磁盘空闲空间（字节） */
    private long diskFree;
}
