package com.ljwx.platform.core.cache;

/**
 * Cache level enumeration for multi-level cache strategy.
 *
 * <p>Defines three cache tiers:
 * <ul>
 *   <li>REDIS_ONLY: Strong consistency, uses only Redis L2 cache</li>
 *   <li>CAFFEINE_REDIS: Eventual consistency, uses Caffeine L1 + Redis L2</li>
 *   <li>CAFFEINE_ONLY: Local consistency, uses only Caffeine L1 cache</li>
 * </ul>
 */
public enum CacheLevel {

    /**
     * Redis only - strong consistency.
     * Suitable for: permissions, menus, data scopes.
     * No local cache, all reads/writes go to Redis.
     */
    REDIS_ONLY,

    /**
     * Caffeine + Redis - eventual consistency.
     * Suitable for: dictionaries, configurations, tenant info.
     * L1 cache (Caffeine) with TTL 60s, L2 cache (Redis) with configurable TTL.
     */
    CAFFEINE_REDIS,

    /**
     * Caffeine only - local consistency.
     * Suitable for: static data, enums.
     * Only local cache with TTL 300s, no distributed cache.
     */
    CAFFEINE_ONLY
}
