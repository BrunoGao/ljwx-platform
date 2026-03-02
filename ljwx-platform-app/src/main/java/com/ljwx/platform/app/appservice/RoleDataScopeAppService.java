package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.RoleDataScopeUpdateDTO;
import com.ljwx.platform.app.domain.entity.RoleDataScope;
import com.ljwx.platform.app.domain.entity.SysDept;
import com.ljwx.platform.app.domain.vo.RoleDataScopeVO;
import com.ljwx.platform.app.infra.mapper.RoleDataScopeMapper;
import com.ljwx.platform.app.infra.mapper.SysDeptMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 角色数据范围应用服务。
 *
 * <p>管理角色的自定义数据范围（CUSTOM 类型）。
 *
 * <h3>缓存策略</h3>
 * <ul>
 *   <li>查询角色数据范围：Caffeine L1 缓存，TTL 300s</li>
 *   <li>更新数据范围：失效缓存</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class RoleDataScopeAppService {

    private final RoleDataScopeMapper roleDataScopeMapper;
    private final SysDeptMapper sysDeptMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 查询角色的自定义数据范围。
     *
     * @param roleId 角色 ID
     * @return 角色数据范围 VO
     */
    @Cacheable(cacheNames = "roleDataScope", key = "#roleId")
    public RoleDataScopeVO getByRoleId(Long roleId) {
        if (roleId == null) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "角色 ID 不能为空");
        }

        // 查询角色绑定的部门 ID 列表
        List<Long> deptIds = roleDataScopeMapper.selectDeptIdsByRoleId(roleId);

        // 查询部门名称
        List<String> deptNames = new ArrayList<>();
        if (!deptIds.isEmpty()) {
            List<SysDept> depts = deptIds.stream()
                    .map(sysDeptMapper::selectById)
                    .filter(dept -> dept != null)
                    .collect(Collectors.toList());
            deptNames = depts.stream()
                    .map(SysDept::getName)
                    .collect(Collectors.toList());
        }

        RoleDataScopeVO vo = new RoleDataScopeVO();
        vo.setRoleId(roleId);
        vo.setDeptIds(deptIds);
        vo.setDeptNames(deptNames);
        return vo;
    }

    /**
     * 更新角色的自定义数据范围。
     *
     * <p>删除旧记录，插入新记录，并失效缓存。
     *
     * @param roleId 角色 ID
     * @param dto    更新 DTO
     */
    @Transactional
    @CacheEvict(cacheNames = "roleDataScope", key = "#roleId")
    public void update(Long roleId, RoleDataScopeUpdateDTO dto) {
        if (roleId == null) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "角色 ID 不能为空");
        }
        if (dto == null || dto.getDeptIds() == null) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "部门 ID 列表不能为空");
        }

        // 1. 删除旧记录（逻辑删除）
        roleDataScopeMapper.deleteByRoleId(roleId);

        // 2. 插入新记录
        if (!dto.getDeptIds().isEmpty()) {
            List<RoleDataScope> records = new ArrayList<>();
            LocalDateTime now = LocalDateTime.now();

            for (Long deptId : dto.getDeptIds()) {
                RoleDataScope record = new RoleDataScope();
                record.setId(idGenerator.nextId());
                record.setRoleId(roleId);
                record.setDeptId(deptId);
                // tenantId 由 TenantLineInterceptor 自动注入
                record.setCreatedBy(0L);  // 由 AuditFieldInterceptor 自动填充
                record.setCreatedTime(now);
                record.setUpdatedBy(0L);
                record.setUpdatedTime(now);
                record.setDeleted(false);
                record.setVersion(1);
                records.add(record);
            }

            roleDataScopeMapper.batchInsert(records);
        }
    }

    /**
     * 根据多个角色 ID 查询自定义部门列表（去重）。
     *
     * <p>用于 DataScopeInterceptor 拼接 SQL 条件。
     *
     * @param roleIds 角色 ID 列表
     * @return 部门 ID 列表
     */
    @Cacheable(cacheNames = "roleDataScope", key = "'multi:' + #roleIds.toString()")
    public List<Long> getCustomDeptIdsByRoleIds(List<Long> roleIds) {
        if (roleIds == null || roleIds.isEmpty()) {
            return new ArrayList<>();
        }
        return roleDataScopeMapper.selectDeptIdsByRoleIds(roleIds);
    }
}
