package com.ljwx.platform.app.vo.screen;

import lombok.Data;

import java.util.List;

/**
 * Screen trend data.
 */
@Data
public class ScreenTrendVO {

    private List<ScreenTrendItemVO> userTrend;

    private List<ScreenTrendItemVO> loginTrend;
}
