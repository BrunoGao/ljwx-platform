package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.core.domain.ImportExportTask;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * Import/Export Task Mapper
 *
 * @author LJWX Platform
 * @since Phase 46
 */
@Mapper
public interface ImportExportTaskMapper {

    int insert(ImportExportTask task);

    int updateById(ImportExportTask task);

    int deleteById(Long id);

    ImportExportTask selectById(Long id);

    List<ImportExportTask> selectList(ImportExportTask query);

    long count(ImportExportTask query);
}
