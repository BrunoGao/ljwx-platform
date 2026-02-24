package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.RoleCreateDTO;
import com.ljwx.platform.app.domain.dto.RoleQueryDTO;
import com.ljwx.platform.app.domain.dto.RoleUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysRole;
import com.ljwx.platform.app.domain.vo.RoleVO;
import com.ljwx.platform.app.infra.mapper.SysRoleMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 角色应用服务（CRUD）。
 */
@Service
@RequiredArgsConstructor
public class RoleAppService {

    private final SysRoleMapper roleMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder tenantHolder;
    private final CurrentUserHolder userHolder;

    public PageResult<RoleVO> listRoles(RoleQueryDTO query) {
        List<SysRole> roles = roleMapper.selectList(query);
        long total = roleMapper.countList(query);
        List<RoleVO> vos = roles.stream().map(this::toVO).collect(Collectors.toList());
        return new PageResult<>(vos, total);
    }

    public RoleVO getRole(Long id) {
        SysRole role = roleMapper.selectById(id);
        if (role == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "角色不存在");
        }
        return toVO(role);
    }

    @Transactional
    public Long createRole(RoleCreateDTO dto) {
        Long tenantId = tenantHolder.getTenantId();
        Long currentUserId = resolveCurrentUserId();

        long id = idGenerator.nextId();
        SysRole role = new SysRole();
        role.setId(id);
        role.setTenantId(tenantId);
        role.setName(dto.getName());
        role.setCode(dto.getCode());
        role.setRemark(dto.getDescription());
        role.setStatus(1);
        // createdBy/Time, updatedBy/Time 由 AuditFieldInterceptor 自动填充

        roleMapper.insert(role);

        if (dto.getPermissionIds() != null && !dto.getPermissionIds().isEmpty()) {
            for (Long permId : dto.getPermissionIds()) {
                roleMapper.insertRolePermission(idGenerator.nextId(), id, permId,
                        tenantId, currentUserId, currentUserId);
            }
        }

        return id;
    }

    @Transactional
    public void updateRole(Long id, RoleUpdateDTO dto) {
        SysRole role = roleMapper.selectById(id);
        if (role == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "角色不存在");
        }

        if (dto.getName()        != null) { role.setName(dto.getName());            }
        if (dto.getCode()        != null) { role.setCode(dto.getCode());            }
        if (dto.getDescription() != null) { role.setRemark(dto.getDescription());  }
        if (dto.getStatus()      != null) { role.setStatus(dto.getStatus());        }
        if (dto.getVersion()     != null) { role.setVersion(dto.getVersion());      }

        roleMapper.updateById(role);

        if (dto.getPermissionIds() != null) {
            Long tenantId = tenantHolder.getTenantId();
            Long currentUserId = resolveCurrentUserId();
            roleMapper.deleteRolePermissions(id);
            for (Long permId : dto.getPermissionIds()) {
                roleMapper.insertRolePermission(idGenerator.nextId(), id, permId,
                        tenantId, currentUserId, currentUserId);
            }
        }
    }

    @Transactional
    public void deleteRole(Long id) {
        roleMapper.deleteById(id);
        roleMapper.deleteRolePermissions(id);
    }

    private RoleVO toVO(SysRole role) {
        RoleVO vo = new RoleVO();
        vo.setId(role.getId());
        vo.setName(role.getName());
        vo.setCode(role.getCode());
        vo.setDescription(role.getRemark());
        vo.setStatus(role.getStatus());
        vo.setCreatedTime(role.getCreatedTime());
        vo.setUpdatedTime(role.getUpdatedTime());
        vo.setPermissions(roleMapper.selectPermissionsForRole(role.getId()));
        return vo;
    }

    private Long resolveCurrentUserId() {
        Long uid = userHolder.getUserId();
        return uid != null ? uid : 0L;
    }
}
