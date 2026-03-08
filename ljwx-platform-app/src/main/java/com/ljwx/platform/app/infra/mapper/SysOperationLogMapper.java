package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.OperationLogQueryDTO;
import com.ljwx.platform.app.domain.entity.SysOperationLog;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 操作日志 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysOperationLogMapper {

    int insert(SysOperationLog operationLog);

    SysOperationLog selectById(Long id);

    List<SysOperationLog> selectList(OperationLogQueryDTO query);

    long countList(OperationLogQueryDTO query);

    int deleteById(Long id);

    int cleanAll();
}
