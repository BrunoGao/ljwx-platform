package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.UserCreateDTO;
import com.ljwx.platform.app.domain.dto.UserQueryDTO;
import com.ljwx.platform.app.domain.dto.UserUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysUser;
import com.ljwx.platform.app.domain.vo.UserVO;
import com.ljwx.platform.app.infra.mapper.SysUserMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 用户应用服务（CRUD）。
 *
 * <p>tenant_id 不在 DTO 中传递，由 TenantLineInterceptor 自动注入 SELECT 查询，
 * INSERT 时由 CurrentTenantHolder 手动设置到实体上。
 */
@Service
@RequiredArgsConstructor
public class UserAppService {

    private final SysUserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder tenantHolder;
    private final CurrentUserHolder userHolder;

    public PageResult<UserVO> listUsers(UserQueryDTO query) {
        List<SysUser> users = userMapper.selectList(query);
        long total = userMapper.countList(query);
        List<UserVO> vos = users.stream().map(this::toVO).collect(Collectors.toList());
        return new PageResult<>(vos, total);
    }

    public UserVO getUser(Long id) {
        SysUser user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在");
        }
        return toVO(user);
    }

    @Transactional
    public Long createUser(UserCreateDTO dto) {
        Long tenantId = tenantHolder.getTenantId();
        Long currentUserId = resolveCurrentUserId();

        long id = idGenerator.nextId();
        SysUser user = new SysUser();
        user.setId(id);
        user.setTenantId(tenantId);
        user.setUsername(dto.getUsername());
        user.setPassword(passwordEncoder.encode(dto.getPassword()));
        user.setNickname(dto.getNickname());
        user.setEmail(dto.getEmail());
        user.setPhone(dto.getPhone());
        user.setStatus(1);
        // createdBy/Time, updatedBy/Time 由 AuditFieldInterceptor 自动填充

        userMapper.insert(user);

        if (dto.getRoleIds() != null && !dto.getRoleIds().isEmpty()) {
            for (Long roleId : dto.getRoleIds()) {
                userMapper.insertUserRole(idGenerator.nextId(), id, roleId,
                        tenantId, currentUserId, currentUserId);
            }
        }

        return id;
    }

    @Transactional
    public void updateUser(Long id, UserUpdateDTO dto) {
        SysUser user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在");
        }

        if (dto.getNickname() != null) { user.setNickname(dto.getNickname()); }
        if (dto.getEmail()    != null) { user.setEmail(dto.getEmail());       }
        if (dto.getPhone()    != null) { user.setPhone(dto.getPhone());       }
        if (dto.getStatus()   != null) { user.setStatus(dto.getStatus());     }
        // version：客户端未传时沿用 DB 当前值（跳过乐观锁）
        if (dto.getVersion()  != null) { user.setVersion(dto.getVersion());   }
        // updatedBy/Time 由 AuditFieldInterceptor 自动刷新

        userMapper.updateById(user);

        if (dto.getRoleIds() != null) {
            Long tenantId = tenantHolder.getTenantId();
            Long currentUserId = resolveCurrentUserId();
            userMapper.deleteUserRoles(id);
            for (Long roleId : dto.getRoleIds()) {
                userMapper.insertUserRole(idGenerator.nextId(), id, roleId,
                        tenantId, currentUserId, currentUserId);
            }
        }
    }

    @Transactional
    public void deleteUser(Long id) {
        userMapper.deleteById(id);
        userMapper.deleteUserRoles(id);
    }

    private UserVO toVO(SysUser user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setNickname(user.getNickname());
        vo.setEmail(user.getEmail());
        vo.setPhone(user.getPhone());
        vo.setAvatar(user.getAvatar());
        vo.setStatus(user.getStatus());
        vo.setCreatedTime(user.getCreatedTime());
        vo.setUpdatedTime(user.getUpdatedTime());
        vo.setRoles(userMapper.selectRolesForUser(user.getId()));
        return vo;
    }

    private Long resolveCurrentUserId() {
        Long uid = userHolder.getUserId();
        return uid != null ? uid : 0L;
    }
}
