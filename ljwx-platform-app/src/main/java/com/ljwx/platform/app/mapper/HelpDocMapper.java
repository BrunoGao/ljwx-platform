package com.ljwx.platform.app.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ljwx.platform.app.domain.HelpDoc;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * Help documentation mapper
 */
@Mapper
public interface HelpDocMapper extends BaseMapper<HelpDoc> {

    /**
     * Find help doc by route match (exact match first, then prefix match)
     *
     * @param routePath route path
     * @param tenantId tenant ID
     * @return help doc
     */
    HelpDoc findByRouteMatch(@Param("routePath") String routePath, @Param("tenantId") Long tenantId);

    /**
     * List help docs by category
     *
     * @param category category (nullable)
     * @param tenantId tenant ID
     * @return help doc list
     */
    List<HelpDoc> listByCategory(@Param("category") String category, @Param("tenantId") Long tenantId);
}
