package com.ljwx.platform.core.cache.config;

import com.ljwx.platform.core.cache.CacheInvalidationListener;
import com.ljwx.platform.core.cache.MultiLevelCacheManager;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.listener.ChannelTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.net.InetAddress;
import java.net.UnknownHostException;

/**
 * Cache configuration for multi-level cache manager.
 *
 * <p>Configures:</p>
<ul>
 *   <li>RedisTemplate with JSON serialization</li>
 *   <li>MultiLevelCacheManager with Caffeine L1 + Redis L2</li>
 *   <li>Redis Pub/Sub listener for cache invalidation</li>
 * </ul>
 *
 * <p>This configuration is only active when Redis is available.</p>
 */
@Configuration
@ConditionalOnClass(RedisConnectionFactory.class)
@ConditionalOnProperty(name = "cache.enabled", havingValue = "true", matchIfMissing = true)
public class CacheConfig {

    @Value("${cache.redis.key-prefix:ljwx:cache:}")
    private String keyPrefix;

    @Value("${cache.caffeine.max-size:10000}")
    private int caffeineMaxSize;

    @Value("${cache.caffeine.expire-after-write:300}")
    private long caffeineExpireSeconds;

    @Value("${cache.pubsub.channel:cache:invalidation}")
    private String pubsubChannel;

    /**
     * RedisTemplate with JSON serialization.
     */
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);

        // Use String serializer for keys
        StringRedisSerializer stringSerializer = new StringRedisSerializer();
        template.setKeySerializer(stringSerializer);
        template.setHashKeySerializer(stringSerializer);

        // Use JSON serializer for values
        GenericJackson2JsonRedisSerializer jsonSerializer = new GenericJackson2JsonRedisSerializer();
        template.setValueSerializer(jsonSerializer);
        template.setHashValueSerializer(jsonSerializer);

        template.afterPropertiesSet();
        return template;
    }

    /**
     * Multi-level cache manager.
     */
    @Bean
    public MultiLevelCacheManager multiLevelCacheManager(RedisTemplate<String, Object> redisTemplate) {
        String podId = getPodId();
        return new MultiLevelCacheManager(
                redisTemplate,
                keyPrefix,
                podId,
                caffeineMaxSize,
                caffeineExpireSeconds
        );
    }

    /**
     * Redis message listener container for Pub/Sub.
     */
    @Bean
    public RedisMessageListenerContainer redisMessageListenerContainer(
            RedisConnectionFactory connectionFactory,
            CacheInvalidationListener cacheInvalidationListener) {
        RedisMessageListenerContainer container = new RedisMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);
        container.addMessageListener(cacheInvalidationListener, new ChannelTopic(pubsubChannel));
        return container;
    }

    /**
     * Cache invalidation listener.
     */
    @Bean
    public CacheInvalidationListener cacheInvalidationListener(
            MultiLevelCacheManager cacheManager,
            RedisTemplate<String, Object> redisTemplate) {
        @SuppressWarnings("unchecked")
        RedisSerializer<Object> serializer = (RedisSerializer<Object>) redisTemplate.getValueSerializer();
        return new CacheInvalidationListener(cacheManager, serializer);
    }

    /**
     * Get pod identifier.
     * Uses hostname in Kubernetes, falls back to localhost.
     */
    private String getPodId() {
        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            return "localhost-" + System.currentTimeMillis();
        }
    }
}
