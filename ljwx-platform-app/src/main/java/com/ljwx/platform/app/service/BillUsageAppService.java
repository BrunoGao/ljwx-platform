package com.ljwx.platform.app.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.ljwx.platform.app.domain.BillUsageRecord;
import com.ljwx.platform.app.dto.billing.BillingQueryDTO;
import com.ljwx.platform.app.mapper.BillUsageRecordMapper;
import com.ljwx.platform.app.vo.billing.TenantUsageSummaryVO;
import com.ljwx.platform.app.vo.billing.UsageRecordVO;
import com.ljwx.platform.core.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;

import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Bill usage app service
 */
@Service
@RequiredArgsConstructor
public class BillUsageAppService {

    private final BillUsageRecordMapper billUsageRecordMapper;

    /**
     * List usage records
     *
     * @param query query DTO
     * @return usage record list
     */
    public List<UsageRecordVO> listUsageRecords(BillingQueryDTO query) {
        // Validate date range
        if (query.getEndDate().isBefore(query.getStartDate())) {
            throw new BusinessException("End date must be >= start date");
        }

        long daysBetween = ChronoUnit.DAYS.between(query.getStartDate(), query.getEndDate());
        if (daysBetween > 365) {
            throw new BusinessException("Date range cannot exceed 365 days");
        }

        // Build query
        LambdaQueryWrapper<BillUsageRecord> wrapper = new LambdaQueryWrapper<>();
        wrapper.ge(BillUsageRecord::getRecordDate, query.getStartDate())
                .le(BillUsageRecord::getRecordDate, query.getEndDate());

        if (query.getMetricType() != null && !query.getMetricType().isEmpty()) {
            wrapper.eq(BillUsageRecord::getMetricType, query.getMetricType());
        }

        wrapper.orderByDesc(BillUsageRecord::getRecordDate);

        List<BillUsageRecord> records = billUsageRecordMapper.selectList(wrapper);

        return records.stream().map(record -> {
            UsageRecordVO vo = new UsageRecordVO();
            BeanUtils.copyProperties(record, vo);
            return vo;
        }).collect(Collectors.toList());
    }

    /**
     * Get tenant usage summary list (superadmin only)
     *
     * @return tenant usage summary list
     */
    public List<TenantUsageSummaryVO> getTenantUsageSummary() {
        return billUsageRecordMapper.getTenantUsageSummaryList();
    }
}
