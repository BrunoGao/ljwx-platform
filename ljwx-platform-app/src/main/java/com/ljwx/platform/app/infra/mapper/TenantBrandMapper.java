package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.TenantBrand;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 租户品牌配置 Mapper
 *
 * @author LJWX Platform
 * @since Phase 38
 */
@Mapper
public interface TenantBrandMapper {

    /**
     * 根据租户 ID 查询品牌配置
     *
     * @param tenantId 租户 ID
     * @return 品牌配置
     */
    TenantBrand selectByTenantId(@Param("tenantId") Long tenantId);

    /**
     * 插入品牌配置
     *
     * @param brand 品牌配置
     */
    void insert(TenantBrand brand);

    /**
     * 根据 ID 更新品牌配置
     *
     * @param brand 品牌配置
     */
    void updateById(TenantBrand brand);
}
