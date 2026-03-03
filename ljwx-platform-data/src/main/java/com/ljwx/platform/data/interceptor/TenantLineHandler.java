package com.ljwx.platform.data.interceptor;

import com.ljwx.platform.core.context.CurrentTenantHolder;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.util.Set;

/**
 * Tenant line handler that determines whether to apply tenant filtering.
 *
 * <h3>Super Admin Mechanism</h3>
 * <p>When the current user's tenant_id is 0 (super admin), this handler returns {@code null}
 * from {@link #getTenantId()}, which signals to the {@link TenantLineInterceptor} to skip
 * the tenant filter entirely. This allows super admins to query data across all tenants.
 *
 * <h3>Platform Tables</h3>
 * <p>Tables without a {@code tenant_id} column (e.g., Quartz tables with {@code QRTZ_} prefix)
 * are excluded via {@link #shouldIgnoreTable(String)}.
 *
 * <h3>DAG Compliance</h3>
 * <p>Depends only on {@code core} interfaces. The actual {@link CurrentTenantHolder}
 * implementation is injected at runtime by the {@code security} module.
 */
@Component
@RequiredArgsConstructor
public class TenantLineHandler {

    /**
     * Platform-level tables excluded from tenant filtering.
     *
     * <p>Includes:
     * <ul>
     *   <li>Infrastructure tables without tenant_id (Quartz)</li>
     *   <li>System registry tables that must be globally readable (sys_tenant)</li>
     * </ul>
     */
    private static final Set<String> PLATFORM_TABLES = Set.of(
            // Quartz scheduler tables
            "qrtz_job_details",
            "qrtz_triggers",
            "qrtz_simple_triggers",
            "qrtz_cron_triggers",
            "qrtz_simprop_triggers",
            "qrtz_blob_triggers",
            "qrtz_calendars",
            "qrtz_paused_trigger_grps",
            "qrtz_fired_triggers",
            "qrtz_scheduler_state",
            "qrtz_locks",

            // Tenant registry table: rows are system-level (tenant_id=0)
            "sys_tenant"
    );

    /**
     * Optional provider for the current-tenant context.
     * Returns {@code null} when no implementation is registered.
     */
    private final ObjectProvider<CurrentTenantHolder> tenantHolderProvider;

    /**
     * Returns the tenant ID to be used in the WHERE clause.
     *
     * <p>Returns {@code null} in two cases:
     * <ul>
     *   <li>No authenticated user (unauthenticated requests)</li>
     *   <li>Super admin (tenant_id = 0) — skips tenant filtering</li>
     * </ul>
     *
     * @return tenant ID, or {@code null} to skip filtering
     */
    public Long getTenantId() {
        Long tenantId = resolveTenantId();

        // Super admin (tenant_id=0) or unauthenticated — skip tenant filter
        if (tenantId == null || Long.valueOf(0).equals(tenantId)) {
            return null;
        }

        return tenantId;
    }

    /**
     * Determines whether a table should be excluded from tenant filtering.
     *
     * @param tableName the table name (case-insensitive)
     * @return {@code true} if the table should be excluded
     */
    public boolean shouldIgnoreTable(String tableName) {
        if (tableName == null) {
            return false;
        }
        // Platform-level tables without tenant_id column
        return PLATFORM_TABLES.contains(tableName.toLowerCase());
    }

    /**
     * Resolves the current tenant ID from the security context.
     * Returns {@code null} when no authenticated tenant is present.
     */
    private Long resolveTenantId() {
        try {
            CurrentTenantHolder holder = tenantHolderProvider.getIfAvailable();
            if (holder != null) {
                return holder.getTenantId();
            }
        } catch (Exception ignored) {
            // Context not available — safe to ignore
        }
        return null;
    }
}
