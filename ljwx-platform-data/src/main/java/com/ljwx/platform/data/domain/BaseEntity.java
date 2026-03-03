package com.ljwx.platform.data.domain;

import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Backward-compatible data layer base entity with ID field.
 *
 * <p>New code should prefer {@code com.ljwx.platform.core.entity.BaseEntity}.
 * This adapter keeps historical app domain models compiling while the
 * migration is in progress.
 */
@Data
@EqualsAndHashCode(callSuper = true)
public abstract class BaseEntity extends com.ljwx.platform.core.entity.BaseEntity {

    /**
     * Primary key for legacy entities managed in app module.
     */
    private Long id;
}
