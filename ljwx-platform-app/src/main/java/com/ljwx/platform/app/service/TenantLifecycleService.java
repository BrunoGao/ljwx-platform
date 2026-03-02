package com.ljwx.platform.app.service;

import com.ljwx.platform.app.domain.entity.SysTenant;
import com.ljwx.platform.app.infra.mapper.SysTenantMapper;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 租户生命周期管理服务。
 *
 * <p>提供租户冻结、解冻、注销功能，并写入 Outbox 事件保证最终一致性。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TenantLifecycleService {

    private final SysTenantMapper tenantMapper;
    private final OutboxEventPublisher outboxEventPublisher;

    /**
     * 冻结租户。
     *
     * @param tenantId 租户 ID
     * @param reason   冻结原因
     */
    @Transactional
    public void freeze(Long tenantId, String reason) {
        log.info("Freezing tenant: tenantId={}, reason={}", tenantId, reason);

        SysTenant tenant = tenantMapper.selectById(tenantId);
        if (tenant == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在");
        }

        if ("FROZEN".equals(tenant.getLifecycleStatus())) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "租户已处于冻结状态");
        }

        if ("CANCELLED".equals(tenant.getLifecycleStatus())) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "已注销的租户无法冻结");
        }

        LocalDateTime now = LocalDateTime.now();
        int updated = tenantMapper.updateToFrozen(tenantId, reason, now);
        if (updated == 0) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "冻结租户失败");
        }

        // 写入 Outbox 事件
        Map<String, Object> payload = new HashMap<>();
        payload.put("tenantId", tenantId);
        payload.put("reason", reason);
        payload.put("frozenTime", now);
        outboxEventPublisher.publish("Tenant", tenantId, "TENANT_FROZEN", payload);

        log.info("Tenant frozen successfully: tenantId={}", tenantId);
    }

    /**
     * 解冻租户。
     *
     * @param tenantId 租户 ID
     */
    @Transactional
    public void unfreeze(Long tenantId) {
        log.info("Unfreezing tenant: tenantId={}", tenantId);

        SysTenant tenant = tenantMapper.selectById(tenantId);
        if (tenant == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在");
        }

        if (!"FROZEN".equals(tenant.getLifecycleStatus())) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "只能解冻已冻结的租户");
        }

        int updated = tenantMapper.updateToActive(tenantId);
        if (updated == 0) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "解冻租户失败");
        }

        // 写入 Outbox 事件
        Map<String, Object> payload = new HashMap<>();
        payload.put("tenantId", tenantId);
        payload.put("unfrozenTime", LocalDateTime.now());
        outboxEventPublisher.publish("Tenant", tenantId, "TENANT_UNFROZEN", payload);

        log.info("Tenant unfrozen successfully: tenantId={}", tenantId);
    }

    /**
     * 注销租户。
     *
     * @param tenantId 租户 ID
     * @param reason   注销原因
     */
    @Transactional
    public void cancel(Long tenantId, String reason) {
        log.info("Cancelling tenant: tenantId={}, reason={}", tenantId, reason);

        SysTenant tenant = tenantMapper.selectById(tenantId);
        if (tenant == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在");
        }

        if ("CANCELLED".equals(tenant.getLifecycleStatus())) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "租户已处于注销状态");
        }

        LocalDateTime now = LocalDateTime.now();
        int updated = tenantMapper.updateToCancelled(tenantId, reason, now);
        if (updated == 0) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "注销租户失败");
        }

        // 写入 Outbox 事件
        Map<String, Object> payload = new HashMap<>();
        payload.put("tenantId", tenantId);
        payload.put("reason", reason);
        payload.put("cancelledTime", now);
        outboxEventPublisher.publish("Tenant", tenantId, "TENANT_CANCELLED", payload);

        log.info("Tenant cancelled successfully: tenantId={}", tenantId);
    }
}
