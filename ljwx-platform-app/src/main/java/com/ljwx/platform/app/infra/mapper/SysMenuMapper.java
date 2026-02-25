package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.SysMenu;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * sys_menu Mapper。
 *
 * <p>selectAll 由 TenantLineInterceptor 自动注入 tenant_id 过滤。
 */
@Mapper
public interface SysMenuMapper {

    /** 查询当前租户所有未删除菜单，按 sort ASC 排序。 */
    List<SysMenu> selectAll();

    /** 按主键查询单条菜单。 */
    SysMenu selectById(Long id);

    /** 插入菜单记录（AuditFieldInterceptor 自动填充审计字段）。 */
    void insert(SysMenu menu);

    /** 按主键更新菜单（乐观锁 version 校验）。 */
    void updateById(SysMenu menu);

    /** 统计指定父节点下的子菜单数（用于删除前校验）。 */
    int countByParentId(Long parentId);

    /** 软删除菜单。 */
    void deleteById(Long id);
}
