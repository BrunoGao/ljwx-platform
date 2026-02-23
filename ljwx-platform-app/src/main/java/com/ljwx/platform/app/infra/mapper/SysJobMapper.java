package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.SysJob;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 定时任务 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysJobMapper {

    int insert(SysJob job);

    int updateById(SysJob job);

    SysJob selectById(Long id);

    List<SysJob> selectList(SysJob query);

    long countList(SysJob query);

    int deleteById(Long id);
}
