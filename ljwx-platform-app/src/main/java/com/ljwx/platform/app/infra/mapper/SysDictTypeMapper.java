package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.DictQueryDTO;
import com.ljwx.platform.app.domain.entity.SysDictType;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 字典类型 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysDictTypeMapper {

    int insert(SysDictType dictType);

    int updateById(SysDictType dictType);

    SysDictType selectById(Long id);

    List<SysDictType> selectList(DictQueryDTO query);

    long countList(DictQueryDTO query);

    int deleteById(Long id);
}
