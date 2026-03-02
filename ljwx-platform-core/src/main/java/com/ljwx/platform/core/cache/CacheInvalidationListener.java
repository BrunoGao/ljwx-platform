package com.ljwx.platform.core.cache;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.data.redis.serializer.RedisSerializer;

/**
 * Redis Pub/Sub listener for cache invalidation events.
 *
 * <p>Listens to the "cache:invalidation" channel and handles
 * invalidation messages from other pods to maintain cache consistency.
 */
public class CacheInvalidationListener implements MessageListener {

    private static final Logger log = LoggerFactory.getLogger(CacheInvalidationListener.class);

    private final MultiLevelCacheManager cacheManager;
    private final RedisSerializer<Object> serializer;

    public CacheInvalidationListener(
            MultiLevelCacheManager cacheManager,
            RedisSerializer<Object> serializer) {
        this.cacheManager = cacheManager;
        this.serializer = serializer;
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        try {
            Object deserializedMessage = serializer.deserialize(message.getBody());
            if (deserializedMessage instanceof MultiLevelCacheManager.CacheInvalidationMessage) {
                MultiLevelCacheManager.CacheInvalidationMessage invalidationMessage =
                        (MultiLevelCacheManager.CacheInvalidationMessage) deserializedMessage;

                log.debug("Received invalidation message: cacheName={}, key={}, eventType={}, sourcePod={}",
                        invalidationMessage.getCacheName(),
                        invalidationMessage.getKey(),
                        invalidationMessage.getEventType(),
                        invalidationMessage.getSourcePod());

                cacheManager.handleInvalidation(invalidationMessage);
            } else {
                log.warn("Received unknown message type: {}", deserializedMessage.getClass());
            }
        } catch (Exception e) {
            log.error("Failed to handle invalidation message", e);
        }
    }
}
