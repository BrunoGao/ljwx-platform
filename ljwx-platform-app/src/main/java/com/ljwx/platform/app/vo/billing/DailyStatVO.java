package com.ljwx.platform.app.vo.billing;

import lombok.Data;

import java.time.LocalDate;

/**
 * Daily stat VO
 */
@Data
public class DailyStatVO {

    /**
     * Stat date
     */
    private LocalDate date;

    /**
     * Active user count (unique users with login records on this date)
     */
    private Long count;
}
