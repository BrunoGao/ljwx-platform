package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.TenantDomain;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 租户域名 Mapper
 */
@Mapper
public interface TenantDomainMapper {

    /**
     * 根据 ID 查询
     */
    TenantDomain selectById(Long id);

    /**
     * 查询列表
     */
    List<TenantDomain> selectList();

    /**
     * 根据域名查询（包含已删除记录）
     *
     * @param domain 域名
     * @return 租户域名实体
     */
    TenantDomain selectByDomainIncludeDeleted(@Param("domain") String domain);

    /**
     * 根据域名查询（仅启用的）
     */
    TenantDomain selectByDomain(@Param("domain") String domain);

    /**
     * 根据租户 ID 查询主域名
     *
     * @param tenantId 租户 ID
     * @return 主域名实体
     */
    TenantDomain selectPrimaryByTenantId(@Param("tenantId") Long tenantId);

    /**
     * 插入
     */
    void insert(TenantDomain domain);

    /**
     * 更新
     */
    void updateById(TenantDomain domain);

    /**
     * 取消租户的所有主域名标记
     *
     * @param tenantId 租户 ID
     * @return 更新行数
     */
    int clearPrimaryByTenantId(@Param("tenantId") Long tenantId);
}
