package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.LoginLogQueryDTO;
import com.ljwx.platform.app.domain.entity.SysLoginLog;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 登录日志 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysLoginLogMapper {

    int insert(SysLoginLog loginLog);

    SysLoginLog selectById(Long id);

    List<SysLoginLog> selectList(LoginLogQueryDTO query);

    long countList(LoginLogQueryDTO query);
}
