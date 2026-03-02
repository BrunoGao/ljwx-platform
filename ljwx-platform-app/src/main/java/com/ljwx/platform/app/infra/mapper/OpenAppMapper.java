package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.OpenAppQueryDTO;
import com.ljwx.platform.core.domain.OpenApp;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * Open API Application Mapper
 *
 * @author LJWX Platform
 * @since Phase 47
 */
@Mapper
public interface OpenAppMapper {

    /**
     * Insert new application
     *
     * @param app application entity
     * @return affected rows
     */
    int insert(OpenApp app);

    /**
     * Update application by ID
     *
     * @param app application entity
     * @return affected rows
     */
    int updateById(OpenApp app);

    /**
     * Delete application by ID (soft delete)
     *
     * @param id application ID
     * @return affected rows
     */
    int deleteById(@Param("id") Long id);

    /**
     * Select application by ID
     *
     * @param id application ID
     * @return application entity
     */
    OpenApp selectById(@Param("id") Long id);

    /**
     * Select application by app_key
     *
     * @param appKey application key
     * @return application entity
     */
    OpenApp selectByAppKey(@Param("appKey") String appKey);

    /**
     * Select application list with pagination
     *
     * @param query query DTO
     * @return application list
     */
    List<OpenApp> selectList(OpenAppQueryDTO query);

    /**
     * Count total applications
     *
     * @param query query DTO
     * @return total count
     */
    long countList(OpenAppQueryDTO query);
}
