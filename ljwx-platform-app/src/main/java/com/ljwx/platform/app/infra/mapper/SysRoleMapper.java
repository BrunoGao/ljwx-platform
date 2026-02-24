package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.RoleQueryDTO;
import com.ljwx.platform.app.domain.entity.SysRole;
import com.ljwx.platform.app.domain.vo.PermissionVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * sys_role Mapper。
 *
 * <p>selectPermissionsForRole 使用子查询，保证已认证上下文下
 * TenantLineInterceptor 注入 tenant_id 时不发生多表二义性。
 */
@Mapper
public interface SysRoleMapper {

    SysRole selectById(Long id);

    List<SysRole> selectList(RoleQueryDTO query);

    long countList(RoleQueryDTO query);

    /** 加载角色关联的权限列表（含 resource/action 计算列）。 */
    List<PermissionVO> selectPermissionsForRole(Long roleId);

    void insert(SysRole role);

    void updateById(SysRole role);

    void deleteById(Long id);

    /** 软删除角色的全部权限关联记录。 */
    void deleteRolePermissions(Long roleId);

    void insertRolePermission(@Param("id") Long id,
                               @Param("roleId") Long roleId,
                               @Param("permissionId") Long permissionId,
                               @Param("tenantId") Long tenantId,
                               @Param("createdBy") Long createdBy,
                               @Param("updatedBy") Long updatedBy);
}
