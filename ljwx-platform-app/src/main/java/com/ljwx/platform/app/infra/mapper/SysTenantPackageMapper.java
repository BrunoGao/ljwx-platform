package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.TenantPackageQueryDTO;
import com.ljwx.platform.app.domain.entity.SysTenantPackage;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 租户套餐 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysTenantPackageMapper {

    List<SysTenantPackage> selectList(TenantPackageQueryDTO query);

    long countList(TenantPackageQueryDTO query);

    SysTenantPackage selectById(Long id);

    int insert(SysTenantPackage pkg);

    int updateById(SysTenantPackage pkg);

    int deleteById(Long id);
}
