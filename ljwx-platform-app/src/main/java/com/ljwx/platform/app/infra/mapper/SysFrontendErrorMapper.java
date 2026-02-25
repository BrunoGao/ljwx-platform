package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.SysFrontendError;
import org.apache.ibatis.annotations.Mapper;

/**
 * sys_frontend_error Mapper。
 */
@Mapper
public interface SysFrontendErrorMapper {

    void insert(SysFrontendError error);
}
