-- Phase 33: Multi-Level Cache Manager
-- Create cache_invalidation_event table for tracking cache invalidation events

CREATE TABLE cache_invalidation_event (
    id BIGINT NOT NULL,
    cache_name VARCHAR(100) NOT NULL,
    cache_key VARCHAR(500) NOT NULL,
    event_type VARCHAR(20) NOT NULL,
    source_pod VARCHAR(100) NOT NULL,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    created_by BIGINT NOT NULL DEFAULT 0,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- Create indexes
CREATE INDEX idx_cache_name_created_time ON cache_invalidation_event (cache_name, created_time DESC);
CREATE INDEX idx_tenant_id ON cache_invalidation_event (tenant_id);

-- Add comments
COMMENT ON TABLE cache_invalidation_event IS 'Cache invalidation event log for multi-level cache synchronization';
COMMENT ON COLUMN cache_invalidation_event.cache_name IS 'Cache name identifier';
COMMENT ON COLUMN cache_invalidation_event.cache_key IS 'Cache key to invalidate';
COMMENT ON COLUMN cache_invalidation_event.event_type IS 'Event type: EVICT or CLEAR';
COMMENT ON COLUMN cache_invalidation_event.source_pod IS 'Pod identifier that initiated the invalidation';
