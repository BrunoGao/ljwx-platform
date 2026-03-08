package com.ljwx.platform.app.vo.screen;

import lombok.Data;

import java.time.OffsetDateTime;

/**
 * Screen realtime data.
 */
@Data
public class ScreenRealtimeVO {

    private Long onlineUsers;

    private Double qps;

    private Double cpuUsage;

    private Double memoryUsage;

    private OffsetDateTime timestamp;
}
