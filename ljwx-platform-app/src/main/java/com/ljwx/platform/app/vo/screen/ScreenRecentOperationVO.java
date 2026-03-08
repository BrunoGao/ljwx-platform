package com.ljwx.platform.app.vo.screen;

import lombok.Data;

/**
 * Recent operation item for the screen page.
 */
@Data
public class ScreenRecentOperationVO {

    private String username;

    private String action;

    private String time;
}
