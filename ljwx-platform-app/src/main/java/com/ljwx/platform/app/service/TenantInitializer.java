package com.ljwx.platform.app.service;

import com.ljwx.platform.app.domain.entity.SysDept;
import com.ljwx.platform.app.domain.entity.SysRole;
import com.ljwx.platform.app.domain.entity.SysUser;
import com.ljwx.platform.app.infra.mapper.SysDeptMapper;
import com.ljwx.platform.app.infra.mapper.SysRoleMapper;
import com.ljwx.platform.app.infra.mapper.SysUserMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 租户初始化器。
 *
 * <p>在租户创建成功后自动调用，初始化默认数据：
 * <ul>
 *   <li>创建根部门</li>
 *   <li>创建默认角色（TENANT_ADMIN）</li>
 *   <li>创建默认管理员（username=admin）</li>
 *   <li>分配角色给管理员</li>
 * </ul>
 *
 * <p>初始化失败时抛出异常，由调用方回滚租户创建事务。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TenantInitializer {

    private final SysDeptMapper deptMapper;
    private final SysRoleMapper roleMapper;
    private final SysUserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 初始化租户默认数据。
     *
     * @param tenantId 租户 ID
     */
    @Transactional
    public void initialize(Long tenantId) {
        log.info("Initializing tenant: tenantId={}", tenantId);

        try {
            // 1. 创建根部门
            Long rootDeptId = createRootDept(tenantId);

            // 2. 创建默认角色
            Long adminRoleId = createAdminRole(tenantId);

            // 3. 创建默认管理员
            Long adminUserId = createAdminUser(tenantId, rootDeptId);

            // 4. 分配角色给管理员
            assignRoleToUser(adminUserId, adminRoleId, tenantId);

            log.info("Tenant initialized successfully: tenantId={}, rootDeptId={}, adminRoleId={}, adminUserId={}",
                    tenantId, rootDeptId, adminRoleId, adminUserId);
        } catch (Exception e) {
            log.error("Failed to initialize tenant: tenantId={}", tenantId, e);
            throw new RuntimeException("租户初始化失败: " + e.getMessage(), e);
        }
    }

    private Long createRootDept(Long tenantId) {
        Long deptId = idGenerator.nextId();
        SysDept dept = new SysDept();
        dept.setId(deptId);
        dept.setTenantId(tenantId);
        dept.setParentId(0L);
        dept.setName("根部门");
        dept.setSort(0);
        dept.setStatus(1);
        dept.setCreatedBy(0L);
        dept.setCreatedTime(LocalDateTime.now());
        dept.setUpdatedBy(0L);
        dept.setUpdatedTime(LocalDateTime.now());
        dept.setDeleted(false);
        dept.setVersion(1);

        deptMapper.insert(dept);
        return deptId;
    }

    private Long createAdminRole(Long tenantId) {
        Long roleId = idGenerator.nextId();
        SysRole role = new SysRole();
        role.setId(roleId);
        role.setTenantId(tenantId);
        role.setName("租户管理员");
        role.setCode("TENANT_ADMIN");
        role.setStatus(1);
        role.setRemark("租户默认管理员角色");
        role.setCreatedBy(0L);
        role.setCreatedTime(LocalDateTime.now());
        role.setUpdatedBy(0L);
        role.setUpdatedTime(LocalDateTime.now());
        role.setDeleted(false);
        role.setVersion(1);

        roleMapper.insert(role);
        return roleId;
    }

    private Long createAdminUser(Long tenantId, Long deptId) {
        Long userId = idGenerator.nextId();
        SysUser user = new SysUser();
        user.setId(userId);
        user.setTenantId(tenantId);
        user.setUsername("admin");
        user.setPassword(passwordEncoder.encode("Admin@12345"));
        user.setNickname("管理员");
        user.setStatus(1);
        user.setCreatedBy(0L);
        user.setCreatedTime(LocalDateTime.now());
        user.setUpdatedBy(0L);
        user.setUpdatedTime(LocalDateTime.now());
        user.setDeleted(false);
        user.setVersion(1);

        userMapper.insert(user);
        return userId;
    }

    private void assignRoleToUser(Long userId, Long roleId, Long tenantId) {
        Long relationId = idGenerator.nextId();
        userMapper.insertUserRole(relationId, userId, roleId, tenantId, 0L, 0L);
    }
}
