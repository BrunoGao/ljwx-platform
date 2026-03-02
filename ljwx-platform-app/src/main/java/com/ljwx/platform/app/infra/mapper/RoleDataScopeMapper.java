package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.RoleDataScope;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 角色自定义数据范围 Mapper。
 */
@Mapper
public interface RoleDataScopeMapper {

    /**
     * 根据角色 ID 查询自定义部门列表。
     *
     * @param roleId 角色 ID
     * @return 部门 ID 列表
     */
    List<Long> selectDeptIdsByRoleId(@Param("roleId") Long roleId);

    /**
     * 根据多个角色 ID 查询自定义部门列表（去重）。
     *
     * @param roleIds 角色 ID 列表
     * @return 部门 ID 列表
     */
    List<Long> selectDeptIdsByRoleIds(@Param("roleIds") List<Long> roleIds);

    /**
     * 根据角色 ID 删除所有数据范围记录。
     *
     * @param roleId 角色 ID
     * @return 影响行数
     */
    int deleteByRoleId(@Param("roleId") Long roleId);

    /**
     * 批量插入角色数据范围。
     *
     * @param records 记录列表
     * @return 影响行数
     */
    int batchInsert(@Param("records") List<RoleDataScope> records);

    /**
     * 根据角色 ID 查询数据范围记录列表。
     *
     * @param roleId 角色 ID
     * @return 记录列表
     */
    List<RoleDataScope> selectByRoleId(@Param("roleId") Long roleId);
}
