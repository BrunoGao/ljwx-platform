package com.ljwx.platform.core.cache.annotation;

import com.ljwx.platform.core.cache.CacheLevel;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Multi-level cache annotation for method-level caching.
 *
 * <p>Supports three cache levels:
 * <ul>
 *   <li>REDIS_ONLY: Strong consistency</li>
 *   <li>CAFFEINE_REDIS: Eventual consistency (default)</li>
 *   <li>CAFFEINE_ONLY: Local consistency</li>
 * </ul>
 *
 * <p>Example usage:
 * <pre>
 * &#64;MultiLevelCacheable(
 *     cacheName = "permissions",
 *     key = "#userId",
 *     level = CacheLevel.REDIS_ONLY,
 *     ttl = 300
 * )
 * public List&lt;String&gt; getUserPermissions(Long userId) {
 *     // ...
 * }
 * </pre>
 */
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface MultiLevelCacheable {

    /**
     * Cache name identifier.
     * Used to group related cache entries.
     */
    String cacheName();

    /**
     * Cache key expression (SpEL).
     * Default is empty string, which means use method parameters as key.
     *
     * <p>Examples:
     * <ul>
     *   <li>"#userId" - use userId parameter</li>
     *   <li>"#user.id" - use user.id property</li>
     *   <li>"'static'" - use static string</li>
     * </ul>
     */
    String key() default "";

    /**
     * Cache level strategy.
     * Default is CAFFEINE_REDIS for eventual consistency.
     */
    CacheLevel level() default CacheLevel.CAFFEINE_REDIS;

    /**
     * Time-to-live in seconds.
     * Default is 300 seconds (5 minutes).
     */
    long ttl() default 300;

    /**
     * Whether to synchronize cache loading.
     * When true, only one thread loads the value for a given key.
     * Default is false.
     */
    boolean sync() default false;
}
