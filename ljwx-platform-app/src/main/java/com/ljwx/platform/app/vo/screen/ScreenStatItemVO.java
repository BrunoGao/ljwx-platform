package com.ljwx.platform.app.vo.screen;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Name/value pair for screen charts.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ScreenStatItemVO {

    private String name;

    private Long value;
}
