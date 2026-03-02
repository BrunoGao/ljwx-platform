package com.ljwx.platform.app.infra.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ljwx.platform.app.domain.entity.ImportExportTask;
import org.apache.ibatis.annotations.Mapper;

/**
 * Import/Export Task Mapper
 *
 * @author LJWX Platform
 * @since Phase 46
 */
@Mapper
public interface ImportExportTaskMapper extends BaseMapper<ImportExportTask> {
}
