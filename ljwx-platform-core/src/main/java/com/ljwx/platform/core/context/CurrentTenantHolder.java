package com.ljwx.platform.core.context;

/**
 * 当前租户上下文接口。
 *
 * <p>实现由 ljwx-platform-security 模块提供（SecurityContextTenantHolder），
 * 通过 Spring 依赖注入注册为 Bean。data 模块的 TenantLineInterceptor
 * 通过此接口获取 tenant_id，自动追加 WHERE tenant_id = ? 实现行级隔离。
 *
 * <p>接口与实现分离，符合 DAG 约束：
 * core ← {security, data}，data 仅依赖 core 中的此接口。
 */
public interface CurrentTenantHolder {

    /**
     * 获取当前请求所属租户的 ID。
     *
     * @return 租户 ID，未认证时返回 {@code null}
     */
    Long getTenantId();
}
