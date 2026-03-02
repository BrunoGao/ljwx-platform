package com.ljwx.platform.app.domain.vo;

import com.ljwx.platform.core.security.DataMask;
import com.ljwx.platform.core.security.MaskType;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户视图对象（不含密码）。
 */
@Data
public class UserVO {

    private Long id;
    private String username;
    private String nickname;

    @DataMask(type = MaskType.EMAIL)
    private String email;

    @DataMask(type = MaskType.PHONE)
    private String phone;

    private String avatar;
    /** 状态：1-启用，0-禁用 */
    private Integer status;
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
    private List<UserRoleVO> roles;
}
