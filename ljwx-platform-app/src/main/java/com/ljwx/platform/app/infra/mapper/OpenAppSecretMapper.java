package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.domain.OpenAppSecret;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * Open API Secret Mapper
 *
 * @author LJWX Platform
 * @since Phase 48
 */
@Mapper
public interface OpenAppSecretMapper {

    /**
     * Insert secret
     *
     * @param secret Secret entity
     * @return Affected rows
     */
    int insert(OpenAppSecret secret);

    /**
     * Update secret by ID
     *
     * @param secret Secret entity
     * @return Affected rows
     */
    int updateById(OpenAppSecret secret);

    /**
     * Delete secret by ID (soft delete)
     *
     * @param id Secret ID
     * @return Affected rows
     */
    int deleteById(@Param("id") Long id);

    /**
     * Select secret by ID
     *
     * @param id Secret ID
     * @return Secret entity
     */
    OpenAppSecret selectById(@Param("id") Long id);

    /**
     * List secrets by app ID
     *
     * @param appId Application ID
     * @return Secret list
     */
    List<OpenAppSecret> listByAppId(@Param("appId") Long appId);

    /**
     * Count active secrets by app ID
     *
     * @param appId Application ID
     * @return Active secret count
     */
    int countActiveByAppId(@Param("appId") Long appId);

    /**
     * Get latest version by app ID
     *
     * @param appId Application ID
     * @return Latest version number
     */
    Integer getLatestVersionByAppId(@Param("appId") Long appId);
}
