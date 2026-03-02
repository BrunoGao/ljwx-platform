package com.ljwx.platform.core.event;

/**
 * Outbox 事件发布器已移至 app 模块。
 *
 * <p>实际实现位于：
 * {@code com.ljwx.platform.app.service.OutboxEventPublisher}
 *
 * <p>原因：OutboxEventPublisher 需要 Jackson（ObjectMapper）进行 JSON 序列化，
 * 而 core 模块不依赖 Jackson。因此将实现移至 app 模块。
 *
 * @deprecated 使用 {@code com.ljwx.platform.app.service.OutboxEventPublisher} 代替
 */
@Deprecated
public class OutboxEventPublisher {
    // This class has been moved to ljwx-platform-app module
    // See: com.ljwx.platform.app.service.OutboxEventPublisher
}
