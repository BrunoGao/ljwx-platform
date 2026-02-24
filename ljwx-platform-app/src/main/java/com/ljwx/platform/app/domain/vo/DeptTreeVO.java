package com.ljwx.platform.app.domain.vo;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 部门树形视图对象（含子节点列表）
 */
@Data
public class DeptTreeVO {

    private Long id;
    private Long parentId;
    private String name;
    private Integer sort;
    private String leader;
    private Integer status;

    /** 子部门列表 */
    private List<DeptTreeVO> children = new ArrayList<>();
}
