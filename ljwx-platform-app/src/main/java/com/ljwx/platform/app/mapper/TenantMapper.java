package com.ljwx.platform.app.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ljwx.platform.app.domain.Tenant;
import org.apache.ibatis.annotations.Mapper;

/**
 * Backward-compatible tenant mapper for legacy service imports.
 */
@Mapper
public interface TenantMapper extends BaseMapper<Tenant> {
}
