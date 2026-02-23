package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.ConfigQueryDTO;
import com.ljwx.platform.app.domain.entity.SysConfig;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 系统配置 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysConfigMapper {

    int insert(SysConfig config);

    int updateById(SysConfig config);

    SysConfig selectById(Long id);

    SysConfig selectByKey(@Param("configKey") String configKey);

    List<SysConfig> selectList(ConfigQueryDTO query);

    long countList(ConfigQueryDTO query);

    int deleteById(Long id);
}
