package com.ljwx.platform.core.id;

import org.springframework.stereotype.Component;

/**
 * Twitter Snowflake 算法 ID 生成器。
 *
 * <p>生成结构（64 bit）：
 * <pre>
 *  1 位符号位（0）
 *  41 位时间戳（毫秒，相对于 EPOCH）
 *  5  位数据中心 ID（0-31）
 *  5  位工作节点 ID（0-31）
 *  12 位序列号（每毫秒 4096 个 ID）
 * </pre>
 */
@Component
public class SnowflakeIdGenerator {

    /** 自定义 epoch：2024-01-01 00:00:00 UTC */
    private static final long EPOCH = 1_704_067_200_000L;

    private static final int WORKER_ID_BITS      = 5;
    private static final int DATACENTER_ID_BITS  = 5;
    private static final int SEQUENCE_BITS       = 12;

    private static final long MAX_WORKER_ID     = ~(-1L << WORKER_ID_BITS);      // 31
    private static final long MAX_DATACENTER_ID = ~(-1L << DATACENTER_ID_BITS);  // 31

    private static final int WORKER_ID_SHIFT    = SEQUENCE_BITS;                                       // 12
    private static final int DATACENTER_ID_SHIFT = SEQUENCE_BITS + WORKER_ID_BITS;                    // 17
    private static final int TIMESTAMP_LEFT_SHIFT = SEQUENCE_BITS + WORKER_ID_BITS + DATACENTER_ID_BITS; // 22

    private static final long SEQUENCE_MASK = ~(-1L << SEQUENCE_BITS); // 4095

    private final long workerId;
    private final long datacenterId;

    private long sequence    = 0L;
    private long lastTimestamp = -1L;

    /** 默认构造：workerId=1, datacenterId=1 */
    public SnowflakeIdGenerator() {
        this(1L, 1L);
    }

    public SnowflakeIdGenerator(long workerId, long datacenterId) {
        if (workerId < 0 || workerId > MAX_WORKER_ID) {
            throw new IllegalArgumentException(
                    "Worker ID must be between 0 and " + MAX_WORKER_ID + ", but got " + workerId);
        }
        if (datacenterId < 0 || datacenterId > MAX_DATACENTER_ID) {
            throw new IllegalArgumentException(
                    "Datacenter ID must be between 0 and " + MAX_DATACENTER_ID + ", but got " + datacenterId);
        }
        this.workerId      = workerId;
        this.datacenterId  = datacenterId;
    }

    /**
     * 生成下一个全局唯一 ID（线程安全）。
     *
     * @return 64 位 Snowflake ID
     */
    public synchronized long nextId() {
        long timestamp = currentTimeMillis();

        if (timestamp < lastTimestamp) {
            throw new RuntimeException(
                    "Clock moved backwards. Refusing to generate ID for " +
                    (lastTimestamp - timestamp) + " ms.");
        }

        if (lastTimestamp == timestamp) {
            sequence = (sequence + 1) & SEQUENCE_MASK;
            if (sequence == 0) {
                timestamp = waitNextMillis(lastTimestamp);
            }
        } else {
            sequence = 0L;
        }

        lastTimestamp = timestamp;

        return ((timestamp - EPOCH) << TIMESTAMP_LEFT_SHIFT)
                | (datacenterId << DATACENTER_ID_SHIFT)
                | (workerId     << WORKER_ID_SHIFT)
                | sequence;
    }

    private long waitNextMillis(long lastTs) {
        long ts = currentTimeMillis();
        while (ts <= lastTs) {
            ts = currentTimeMillis();
        }
        return ts;
    }

    private long currentTimeMillis() {
        return System.currentTimeMillis();
    }
}
