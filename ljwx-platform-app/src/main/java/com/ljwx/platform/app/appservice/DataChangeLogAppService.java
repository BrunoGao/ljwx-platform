package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.vo.DataChangeLogVO;
import com.ljwx.platform.app.infra.mapper.SysDataChangeLogMapper;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 数据变更审计日志应用服务。
 */
@Service
@RequiredArgsConstructor
public class DataChangeLogAppService {

    private final SysDataChangeLogMapper dataChangeLogMapper;

    /**
     * 查询数据变更日志列表（分页）。
     *
     * @param tableName 表名（可选）
     * @param recordId  记录ID（可选）
     * @param startTime 开始时间（可选）
     * @param endTime   结束时间（可选）
     * @param pageNum   页码
     * @param pageSize  每页大小
     * @return 分页结果
     */
    public PageResult<DataChangeLogVO> listDataChangeLogs(
        String tableName,
        Long recordId,
        LocalDateTime startTime,
        LocalDateTime endTime,
        int pageNum,
        int pageSize
    ) {
        var logs = dataChangeLogMapper.selectList(tableName, recordId, startTime, endTime);
        long total = dataChangeLogMapper.count(tableName, recordId, startTime, endTime);

        // 手动分页
        int start = (pageNum - 1) * pageSize;
        int end = Math.min(start + pageSize, logs.size());
        List<DataChangeLogVO> page = logs.subList(start, end).stream()
            .map(log -> {
                DataChangeLogVO vo = new DataChangeLogVO();
                vo.setId(log.getId());
                vo.setTableName(log.getTableName());
                vo.setRecordId(log.getRecordId());
                vo.setFieldName(log.getFieldName());
                vo.setOldValue(log.getOldValue());
                vo.setNewValue(log.getNewValue());
                vo.setOperateType(log.getOperateType());
                vo.setCreatedBy(log.getCreatedBy());
                vo.setCreatedTime(log.getCreatedTime());
                return vo;
            })
            .collect(Collectors.toList());

        return new PageResult<>(page, total);
    }
}
