package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.SysDictData;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 字典数据 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysDictDataMapper {

    int insert(SysDictData dictData);

    int updateById(SysDictData dictData);

    SysDictData selectById(Long id);

    List<SysDictData> selectByDictType(@Param("dictType") String dictType);

    int deleteById(Long id);
}
