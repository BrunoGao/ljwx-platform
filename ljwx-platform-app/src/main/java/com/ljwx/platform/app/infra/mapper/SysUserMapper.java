package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.UserQueryDTO;
import com.ljwx.platform.app.domain.entity.SysUser;
import com.ljwx.platform.app.domain.vo.UserRoleVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * sys_user Mapper。
 *
 * <p>selectByUsername / selectPermissionCodes / selectRoleCodes 仅在登录流程中调用，
 * 此时无 Auth 上下文，TenantLineInterceptor 会绕过，无 tenant_id 注入。
 *
 * <p>selectRolesForUser 在已认证上下文调用，使用子查询避免多表 tenant_id 二义性。
 */
@Mapper
public interface SysUserMapper {

    /** 按用户名查询（登录专用，无 tenant 过滤）。LIMIT 1 保证单值返回。 */
    SysUser selectByUsername(String username);

    /** 加载用户的全部权限码（登录专用）。 */
    List<String> selectPermissionCodes(Long userId);

    /** 加载用户的全部角色编码（登录专用）。 */
    List<String> selectRoleCodes(Long userId);

    SysUser selectById(Long id);

    List<SysUser> selectList(UserQueryDTO query);

    long countList(UserQueryDTO query);

    /** 加载用户关联的角色简要信息（已认证上下文，子查询实现）。 */
    List<UserRoleVO> selectRolesForUser(Long userId);

    void insert(SysUser user);

    void updateById(SysUser user);

    void deleteById(Long id);

    /** 软删除用户的全部角色关联记录。 */
    void deleteUserRoles(Long userId);

    void insertUserRole(@Param("id") Long id,
                        @Param("userId") Long userId,
                        @Param("roleId") Long roleId,
                        @Param("tenantId") Long tenantId,
                        @Param("createdBy") Long createdBy,
                        @Param("updatedBy") Long updatedBy);
}
