package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.LoginDTO;
import com.ljwx.platform.app.domain.dto.RefreshDTO;
import com.ljwx.platform.app.domain.entity.SysUser;
import com.ljwx.platform.app.domain.vo.LoginVO;
import com.ljwx.platform.app.domain.vo.TokenVO;
import com.ljwx.platform.app.domain.vo.UserInfoVO;
import com.ljwx.platform.app.infra.mapper.SysUserMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.security.blacklist.LoginLockoutService;
import com.ljwx.platform.security.blacklist.TokenBlacklistService;
import com.ljwx.platform.security.jwt.JwtProperties;
import com.ljwx.platform.security.jwt.JwtTokenProvider;
import com.ljwx.platform.web.exception.BusinessException;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 认证应用服务。
 *
 * <p>login / refresh 为公开端点，调用时无 Auth 上下文，
 * TenantLineInterceptor 对所有 DB 查询绕过（tenantId = null）。
 */
@Service
@RequiredArgsConstructor
public class AuthAppService {

    private final SysUserMapper userMapper;
    private final JwtTokenProvider jwtTokenProvider;
    private final JwtProperties jwtProperties;
    private final PasswordEncoder passwordEncoder;
    private final CurrentUserHolder userHolder;
    private final CurrentTenantHolder tenantHolder;
    private final TokenBlacklistService tokenBlacklistService;
    private final LoginLockoutService loginLockoutService;

    /**
     * 用户登录：校验密码 → 加载权限 → 签发双 Token。
     *
     * <p>登录时无 Auth 上下文，TenantLineInterceptor 绕过，
     * selectByUsername 跨租户查询（LIMIT 1 取首条）。
     */
    public LoginVO login(LoginDTO dto) {
        // 0. 检查账号是否被锁定
        if (loginLockoutService.isLocked(dto.getUsername())) {
            throw new BusinessException(ErrorCode.ACCOUNT_LOCKED, "账号已锁定，请30分钟后重试");
        }

        // 1. 按用户名查询（无 tenant 过滤）
        SysUser user = userMapper.selectByUsername(dto.getUsername());
        if (user == null) {
            loginLockoutService.recordFailure(dto.getUsername());
            throw new BusinessException(ErrorCode.TOKEN_INVALID, "用户名或密码错误");
        }

        // 2. BCrypt 密码校验（日志不输出 password）
        if (!passwordEncoder.matches(dto.getPassword(), user.getPassword())) {
            loginLockoutService.recordFailure(dto.getUsername());
            throw new BusinessException(ErrorCode.TOKEN_INVALID, "用户名或密码错误");
        }

        // 3. 账号状态校验
        if (user.getStatus() == null || user.getStatus() != 1) {
            throw new BusinessException(ErrorCode.TOKEN_INVALID, "账号已禁用");
        }

        // 4. 登录成功，清除失败记录
        loginLockoutService.clearFailure(dto.getUsername());

        // 5. 加载权限码与角色编码
        List<String> authorities = userMapper.selectPermissionCodes(user.getId());
        List<String> roles = userMapper.selectRoleCodes(user.getId());

        // 5. 签发 Access + Refresh Token
        String accessToken = jwtTokenProvider.createAccessToken(
                user.getId(), user.getTenantId(), user.getUsername(), authorities);
        String refreshToken = jwtTokenProvider.createRefreshToken(
                user.getId(), user.getTenantId(), user.getUsername(), authorities);

        // 6. 组装响应
        UserInfoVO userInfo = buildUserInfo(user, authorities, roles);

        LoginVO vo = new LoginVO();
        vo.setAccessToken(accessToken);
        vo.setRefreshToken(refreshToken);
        vo.setExpiresIn(jwtProperties.getAccessTokenExpiration());
        vo.setUserInfo(userInfo);
        return vo;
    }

    /**
     * 刷新令牌：验签 Refresh Token → 重新签发双 Token。
     */
    public TokenVO refresh(RefreshDTO dto) {
        String token = dto.getRefreshToken();
        if (!jwtTokenProvider.isTokenValid(token)) {
            throw new BusinessException(ErrorCode.TOKEN_EXPIRED, "刷新令牌已过期或无效");
        }

        Claims claims = jwtTokenProvider.parseToken(token);
        if (jwtTokenProvider.isAccessToken(claims)) {
            throw new BusinessException(ErrorCode.TOKEN_INVALID, "请使用刷新令牌");
        }

        Long userId = jwtTokenProvider.getUserId(claims);
        Long tenantId = jwtTokenProvider.getTenantId(claims);
        String username = jwtTokenProvider.getUsername(claims);
        List<String> authorities = jwtTokenProvider.getAuthorities(claims);

        String newAccess = jwtTokenProvider.createAccessToken(userId, tenantId, username, authorities);
        String newRefresh = jwtTokenProvider.createRefreshToken(userId, tenantId, username, authorities);

        TokenVO vo = new TokenVO();
        vo.setAccessToken(newAccess);
        vo.setRefreshToken(newRefresh);
        vo.setExpiresIn(jwtProperties.getAccessTokenExpiration());
        return vo;
    }

    /**
     * 获取当前登录用户信息（从 SecurityContext + DB 合并）。
     */
    public UserInfoVO getCurrentUser() {
        Long userId = userHolder.getUserId();
        Long tenantId = tenantHolder.getTenantId();

        if (userId == null) {
            throw new BusinessException(ErrorCode.TOKEN_INVALID, "未登录");
        }

        // 权限列表来自 SecurityContext（由 JwtAuthenticationFilter 填入）
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        List<String> authorities = auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());

        // 角色编码从 DB 加载（已认证上下文，子查询安全）
        List<String> roles = userMapper.selectRoleCodes(userId);

        // 用户基础信息从 DB 加载（获取最新 nickname / avatar 等）
        SysUser user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在");
        }

        return buildUserInfo(user, authorities, roles);
    }

    /**
     * 登出：将当前 access token 的 jti 加入黑名单。
     *
     * @param token Bearer token 字符串（不含 "Bearer " 前缀）
     */
    public void logout(String token) {
        if (token == null || !jwtTokenProvider.isTokenValid(token)) {
            return;
        }
        Claims claims = jwtTokenProvider.parseToken(token);
        String jti = jwtTokenProvider.getJti(claims);
        if (jti != null) {
            long remainingSeconds =
                    (claims.getExpiration().getTime() - System.currentTimeMillis()) / 1000;
            tokenBlacklistService.addToBlacklist(jti, remainingSeconds);
        }
    }

    private UserInfoVO buildUserInfo(SysUser user, List<String> authorities, List<String> roles) {
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
}
