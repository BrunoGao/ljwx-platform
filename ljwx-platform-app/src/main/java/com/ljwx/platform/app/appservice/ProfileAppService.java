package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.PasswordUpdateDTO;
import com.ljwx.platform.app.domain.dto.ProfileUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysUser;
import com.ljwx.platform.app.domain.vo.UserInfoVO;
import com.ljwx.platform.app.infra.mapper.SysUserMapper;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 个人中心应用服务。
 *
 * <p>提供当前登录用户的信息查询、资料修改和密码修改功能。
 * 密码字段日志脱敏：password → ***。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ProfileAppService {

    private final SysUserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final CurrentUserHolder userHolder;

    /**
     * 获取当前登录用户信息。
     */
    public UserInfoVO getProfile() {
        Long userId = userHolder.getUserId();
        SysUser user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在");
        }
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        List<String> authorities = auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());
        List<String> roles = userMapper.selectRoleCodes(userId);

        UserInfoVO vo = new UserInfoVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setNickname(user.getNickname());
        vo.setEmail(user.getEmail());
        vo.setPhone(user.getPhone());
        vo.setAvatar(user.getAvatar());
        vo.setAuthorities(authorities);
        vo.setRoles(roles);
        vo.setTenantId(user.getTenantId());
        return vo;
    }

    /**
     * 修改个人信息（昵称、邮箱、手机）。
     */
    public void updateProfile(ProfileUpdateDTO dto) {
        Long userId = userHolder.getUserId();
        SysUser user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在");
        }
        if (dto.getNickname() != null) {
            user.setNickname(dto.getNickname());
        }
        if (dto.getEmail() != null) {
            user.setEmail(dto.getEmail());
        }
        if (dto.getPhone() != null) {
            user.setPhone(dto.getPhone());
        }
        userMapper.updateById(user);
    }

    /**
     * 修改密码（需验证旧密码）。
     * 日志中密码字段脱敏为 ***，不输出明文。
     */
    public void updatePassword(PasswordUpdateDTO dto) {
        Long userId = userHolder.getUserId();
        SysUser user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在");
        }
        // 验证旧密码（日志不输出 password 明文）
        if (!passwordEncoder.matches(dto.getOldPassword(), user.getPassword())) {
            log.warn("用户 {} 修改密码失败：旧密码不正确，password=***", userId);
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "旧密码不正确");
        }
        user.setPassword(passwordEncoder.encode(dto.getNewPassword()));
        userMapper.updatePassword(userId, user.getPassword());
        log.info("用户 {} 修改密码成功，password=***", userId);
    }
}
