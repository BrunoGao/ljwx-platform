package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.SysDataChangeLog;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 数据变更审计日志 Mapper。
 */
@Mapper
public interface SysDataChangeLogMapper {

    /**
     * 插入数据变更日志。
     *
     * @param log 日志实体
     * @return 影响行数
     */
    int insert(SysDataChangeLog log);

    /**
     * 批量插入数据变更日志。
     *
     * @param logs 日志列表
     * @return 影响行数
     */
    int batchInsert(@Param("logs") List<SysDataChangeLog> logs);

    /**
     * 查询数据变更日志列表（分页）。
     *
     * @param tableName 表名（可选）
     * @param recordId  记录ID（可选）
     * @param startTime 开始时间（可选）
     * @param endTime   结束时间（可选）
     * @return 日志列表
     */
    List<SysDataChangeLog> selectList(
        @Param("tableName") String tableName,
        @Param("recordId") Long recordId,
        @Param("startTime") LocalDateTime startTime,
        @Param("endTime") LocalDateTime endTime
    );

    /**
     * 统计数据变更日志数量。
     *
     * @param tableName 表名（可选）
     * @param recordId  记录ID（可选）
     * @param startTime 开始时间（可选）
     * @param endTime   结束时间（可选）
     * @return 总数
     */
    long count(
        @Param("tableName") String tableName,
        @Param("recordId") Long recordId,
        @Param("startTime") LocalDateTime startTime,
        @Param("endTime") LocalDateTime endTime
    );
}
