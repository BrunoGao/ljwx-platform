package com.ljwx.platform.app.dto;

import lombok.Data;

/**
 * 流程实例查询 DTO。
 */
@Data
public class WfInstanceQueryDTO {

    private String businessKey;
    private String businessType;
    private String status;
    private Integer pageNum = 1;
    private Integer pageSize = 10;
}
