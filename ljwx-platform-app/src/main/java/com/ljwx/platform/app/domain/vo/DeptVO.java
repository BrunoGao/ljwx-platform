package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 部门视图对象（平铺结构）
 */
@Data
public class DeptVO {

    private Long id;
    private Long parentId;
    private String name;
    private Integer sort;
    private String leader;
    private String phone;
    private String email;
    private Integer status;
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
    private Integer version;
}
