package com.ljwx.platform.core.cache;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/**
 * Multi-level cache manager supporting Caffeine L1 + Redis L2 caching.
 *
 * <p>Provides three cache strategies:
 * <ul>
 *   <li>REDIS_ONLY: Direct Redis access, strong consistency</li>
 *   <li>CAFFEINE_REDIS: Caffeine L1 + Redis L2, eventual consistency</li>
 *   <li>CAFFEINE_ONLY: Caffeine L1 only, local consistency</li>
 * </ul>
 *
 * <p>Cache invalidation is broadcast via Redis Pub/Sub to ensure
 * consistency across multiple pods.
 */
public class MultiLevelCacheManager {

    private static final Logger log = LoggerFactory.getLogger(MultiLevelCacheManager.class);

    private final RedisTemplate<String, Object> redisTemplate;
    private final ValueOperations<String, Object> valueOps;
    private final String keyPrefix;
    private final String podId;
    private final int caffeineMaxSize;
    private final long caffeineExpireSeconds;

    /**
     * Cache name -> Caffeine cache instance
     */
    private final ConcurrentHashMap<String, Cache<String, Object>> caffeineCaches = new ConcurrentHashMap<>();

    public MultiLevelCacheManager(
            RedisTemplate<String, Object> redisTemplate,
            String keyPrefix,
            String podId,
            int caffeineMaxSize,
            long caffeineExpireSeconds) {
        this.redisTemplate = redisTemplate;
        this.valueOps = redisTemplate.opsForValue();
        this.keyPrefix = keyPrefix;
        this.podId = podId;
        this.caffeineMaxSize = caffeineMaxSize;
        this.caffeineExpireSeconds = caffeineExpireSeconds;
    }

    /**
     * Get value from cache.
     *
     * @param cacheName cache name
     * @param key cache key
     * @param level cache level
     * @param <T> value type
     * @return cached value or null if not found
     */
    @SuppressWarnings("unchecked")
    public <T> T get(String cacheName, String key, CacheLevel level) {
        switch (level) {
            case REDIS_ONLY:
                return (T) getFromRedis(cacheName, key);

            case CAFFEINE_REDIS:
                // Try L1 first
                Cache<String, Object> l1Cache = getCaffeineCache(cacheName);
                Object l1Value = l1Cache.getIfPresent(key);
                if (l1Value != null) {
                    log.debug("Cache hit L1: cacheName={}, key={}", cacheName, key);
                    return (T) l1Value;
                }

                // Try L2
                Object l2Value = getFromRedis(cacheName, key);
                if (l2Value != null) {
                    log.debug("Cache hit L2: cacheName={}, key={}", cacheName, key);
                    // Backfill L1
                    l1Cache.put(key, l2Value);
                    return (T) l2Value;
                }

                log.debug("Cache miss: cacheName={}, key={}", cacheName, key);
                return null;

            case CAFFEINE_ONLY:
                Cache<String, Object> cache = getCaffeineCache(cacheName);
                return (T) cache.getIfPresent(key);

            default:
                throw new IllegalArgumentException("Unknown cache level: " + level);
        }
    }

    /**
     * Put value into cache.
     *
     * @param cacheName cache name
     * @param key cache key
     * @param value value to cache
     * @param level cache level
     * @param ttl time-to-live in seconds
     */
    public void put(String cacheName, String key, Object value, CacheLevel level, long ttl) {
        if (value == null) {
            return;
        }

        switch (level) {
            case REDIS_ONLY:
                putToRedis(cacheName, key, value, ttl);
                break;

            case CAFFEINE_REDIS:
                // Write to both L1 and L2
                Cache<String, Object> l1Cache = getCaffeineCache(cacheName);
                l1Cache.put(key, value);
                putToRedis(cacheName, key, value, ttl);
                break;

            case CAFFEINE_ONLY:
                Cache<String, Object> cache = getCaffeineCache(cacheName);
                cache.put(key, value);
                break;

            default:
                throw new IllegalArgumentException("Unknown cache level: " + level);
        }

        log.debug("Cache put: cacheName={}, key={}, level={}", cacheName, key, level);
    }

    /**
     * Evict a single cache entry.
     *
     * @param cacheName cache name
     * @param key cache key
     * @param level cache level
     */
    public void evict(String cacheName, String key, CacheLevel level) {
        switch (level) {
            case REDIS_ONLY:
                evictFromRedis(cacheName, key);
                break;

            case CAFFEINE_REDIS:
                // Evict from both L1 and L2
                Cache<String, Object> l1Cache = caffeineCaches.get(cacheName);
                if (l1Cache != null) {
                    l1Cache.invalidate(key);
                }
                evictFromRedis(cacheName, key);
                break;

            case CAFFEINE_ONLY:
                Cache<String, Object> cache = caffeineCaches.get(cacheName);
                if (cache != null) {
                    cache.invalidate(key);
                }
                break;

            default:
                throw new IllegalArgumentException("Unknown cache level: " + level);
        }

        log.debug("Cache evict: cacheName={}, key={}, level={}", cacheName, key, level);

        // Broadcast invalidation event
        broadcastInvalidation(cacheName, key, "EVICT");
    }

    /**
     * Clear all entries in a cache.
     *
     * @param cacheName cache name
     * @param level cache level
     */
    public void clear(String cacheName, CacheLevel level) {
        switch (level) {
            case REDIS_ONLY:
                clearRedisCache(cacheName);
                break;

            case CAFFEINE_REDIS:
                // Clear both L1 and L2
                Cache<String, Object> l1Cache = caffeineCaches.get(cacheName);
                if (l1Cache != null) {
                    l1Cache.invalidateAll();
                }
                clearRedisCache(cacheName);
                break;

            case CAFFEINE_ONLY:
                Cache<String, Object> cache = caffeineCaches.get(cacheName);
                if (cache != null) {
                    cache.invalidateAll();
                }
                break;

            default:
                throw new IllegalArgumentException("Unknown cache level: " + level);
        }

        log.debug("Cache clear: cacheName={}, level={}", cacheName, level);

        // Broadcast invalidation event
        broadcastInvalidation(cacheName, "*", "CLEAR");
    }

    /**
     * Broadcast cache invalidation event via Redis Pub/Sub.
     *
     * @param cacheName cache name
     * @param key cache key
     * @param eventType EVICT or CLEAR
     */
    public void broadcastInvalidation(String cacheName, String key, String eventType) {
        try {
            CacheInvalidationMessage message = new CacheInvalidationMessage(
                    cacheName, key, eventType, podId
            );
            redisTemplate.convertAndSend("cache:invalidation", message);
            log.debug("Broadcast invalidation: cacheName={}, key={}, eventType={}, sourcePod={}",
                    cacheName, key, eventType, podId);
        } catch (Exception e) {
            log.error("Failed to broadcast invalidation: cacheName={}, key={}", cacheName, key, e);
        }
    }

    /**
     * Handle invalidation message from other pods.
     *
     * @param message invalidation message
     */
    public void handleInvalidation(CacheInvalidationMessage message) {
        // Skip messages from self
        if (podId.equals(message.getSourcePod())) {
            return;
        }

        String cacheName = message.getCacheName();
        String key = message.getKey();
        String eventType = message.getEventType();

        log.debug("Handle invalidation: cacheName={}, key={}, eventType={}, sourcePod={}",
                cacheName, key, eventType, message.getSourcePod());

        Cache<String, Object> cache = caffeineCaches.get(cacheName);
        if (cache == null) {
            return;
        }

        if ("CLEAR".equals(eventType)) {
            cache.invalidateAll();
        } else if ("EVICT".equals(eventType)) {
            cache.invalidate(key);
        }
    }

    /**
     * Get or create Caffeine cache instance.
     */
    private Cache<String, Object> getCaffeineCache(String cacheName) {
        return caffeineCaches.computeIfAbsent(cacheName, name ->
                Caffeine.newBuilder()
                        .maximumSize(caffeineMaxSize)
                        .expireAfterWrite(caffeineExpireSeconds, TimeUnit.SECONDS)
                        .build()
        );
    }

    /**
     * Get value from Redis.
     */
    private Object getFromRedis(String cacheName, String key) {
        try {
            String redisKey = buildRedisKey(cacheName, key);
            return valueOps.get(redisKey);
        } catch (Exception e) {
            log.error("Failed to get from Redis: cacheName={}, key={}", cacheName, key, e);
            return null;
        }
    }

    /**
     * Put value to Redis.
     */
    private void putToRedis(String cacheName, String key, Object value, long ttl) {
        try {
            String redisKey = buildRedisKey(cacheName, key);
            valueOps.set(redisKey, value, Duration.ofSeconds(ttl));
        } catch (Exception e) {
            log.error("Failed to put to Redis: cacheName={}, key={}", cacheName, key, e);
        }
    }

    /**
     * Evict from Redis.
     */
    private void evictFromRedis(String cacheName, String key) {
        try {
            String redisKey = buildRedisKey(cacheName, key);
            redisTemplate.delete(redisKey);
        } catch (Exception e) {
            log.error("Failed to evict from Redis: cacheName={}, key={}", cacheName, key, e);
        }
    }

    /**
     * Clear Redis cache by pattern.
     */
    private void clearRedisCache(String cacheName) {
        try {
            String pattern = keyPrefix + cacheName + ":*";
            redisTemplate.keys(pattern).forEach(redisTemplate::delete);
        } catch (Exception e) {
            log.error("Failed to clear Redis cache: cacheName={}", cacheName, e);
        }
    }

    /**
     * Build Redis key with prefix.
     */
    private String buildRedisKey(String cacheName, String key) {
        return keyPrefix + cacheName + ":" + key;
    }

    /**
     * Cache invalidation message for Pub/Sub.
     */
    public static class CacheInvalidationMessage {
        private String cacheName;
        private String key;
        private String eventType;
        private String sourcePod;

        public CacheInvalidationMessage() {
        }

        public CacheInvalidationMessage(String cacheName, String key, String eventType, String sourcePod) {
            this.cacheName = cacheName;
            this.key = key;
            this.eventType = eventType;
            this.sourcePod = sourcePod;
        }

        public String getCacheName() {
            return cacheName;
        }

        public void setCacheName(String cacheName) {
            this.cacheName = cacheName;
        }

        public String getKey() {
            return key;
        }

        public void setKey(String key) {
            this.key = key;
        }

        public String getEventType() {
            return eventType;
        }

        public void setEventType(String eventType) {
            this.eventType = eventType;
        }

        public String getSourcePod() {
            return sourcePod;
        }

        public void setSourcePod(String sourcePod) {
            this.sourcePod = sourcePod;
        }
    }
}
