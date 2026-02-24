package com.ljwx.platform.app.domain.vo;

import lombok.Data;

/**
 * 用户角色简要信息（嵌套在 UserVO.roles 中）。
 */
@Data
public class UserRoleVO {

    private Long id;
    private String name;
    private String code;
}
