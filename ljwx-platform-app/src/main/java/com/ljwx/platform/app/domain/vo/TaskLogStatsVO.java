package com.ljwx.platform.app.domain.vo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 任务执行统计 VO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskLogStatsVO {

    /**
     * 总执行次数
     */
    private Long totalCount;

    /**
     * 成功次数
     */
    private Long successCount;

    /**
     * 失败次数
     */
    private Long failureCount;

    /**
     * 平均耗时（毫秒）
     */
    private Integer avgDuration;

    /**
     * 最大耗时（毫秒）
     */
    private Integer maxDuration;

    /**
     * 最小耗时（毫秒）
     */
    private Integer minDuration;
}
