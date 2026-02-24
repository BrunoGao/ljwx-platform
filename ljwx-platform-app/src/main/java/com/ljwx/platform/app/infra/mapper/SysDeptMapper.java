package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.DeptQueryDTO;
import com.ljwx.platform.app.domain.entity.SysDept;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 部门 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysDeptMapper {

    int insert(SysDept dept);

    int updateById(SysDept dept);

    SysDept selectById(Long id);

    List<SysDept> selectList(DeptQueryDTO query);

    /** 查询所有部门（用于构建树形结构） */
    List<SysDept> selectAll();

    /** 查询直接子部门数量（用于删除前校验） */
    long countChildren(Long parentId);

    int deleteById(Long id);
}
