package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.FileQueryDTO;
import com.ljwx.platform.app.domain.entity.SysFile;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 文件管理 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysFileMapper {

    int insert(SysFile sysFile);

    SysFile selectById(Long id);

    List<SysFile> selectList(FileQueryDTO query);

    long countList(FileQueryDTO query);

    int deleteById(Long id);
}
