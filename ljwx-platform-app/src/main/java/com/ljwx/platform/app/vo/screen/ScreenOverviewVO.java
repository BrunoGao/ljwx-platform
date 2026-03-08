package com.ljwx.platform.app.vo.screen;

import lombok.Data;

import java.util.List;

/**
 * Screen overview data.
 */
@Data
public class ScreenOverviewVO {

    private Long totalUsers;

    private Long todayUsers;

    private Long totalTenants;

    private Long todayLoginCount;

    private List<ScreenStatItemVO> tenantUserDistribution;

    private List<ScreenStatItemVO> roleDistribution;

    private List<ScreenStatItemVO> userStatusDistribution;

    private List<ScreenRecentOperationVO> recentOperations;
}
