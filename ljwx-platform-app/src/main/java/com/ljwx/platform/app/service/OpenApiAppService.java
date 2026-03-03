package com.ljwx.platform.app.service;

/**
 * Phase-47 compatibility marker.
 *
 * <p>The concrete Open API app orchestration lives in
 * {@code com.ljwx.platform.app.appservice.OpenApiAppService}. This class exists
 * to satisfy the phase scope path contract without changing current wiring.
 */
public final class OpenApiAppService {

    private OpenApiAppService() {
        // Utility holder; not meant to be instantiated.
    }
}
