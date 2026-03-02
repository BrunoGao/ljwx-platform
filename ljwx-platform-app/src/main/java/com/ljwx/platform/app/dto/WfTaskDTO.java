package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 流程任务操作 DTO
 *
 * @author LJWX Platform
 * @since Phase 53
 */
@Data
public class WfTaskDTO {

    /**
     * 审批意见
     */
    @Size(max = 500, message = "审批意见长度不能超过500")
    private String comment;
}
