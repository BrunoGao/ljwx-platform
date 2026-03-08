package com.ljwx.platform.app.vo.screen;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Screen trend point.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ScreenTrendItemVO {

    private LocalDate date;

    private Long value;
}
