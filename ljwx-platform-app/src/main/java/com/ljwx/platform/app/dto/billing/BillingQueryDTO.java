package com.ljwx.platform.app.dto.billing;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

/**
 * Billing query DTO
 */
@Data
public class BillingQueryDTO {

    /**
     * Query start date
     */
    @NotNull(message = "Start date cannot be null")
    private LocalDate startDate;

    /**
     * Query end date (must be >= startDate, max span 365 days)
     */
    @NotNull(message = "End date cannot be null")
    private LocalDate endDate;

    /**
     * Metric type filter (optional, returns all types if not provided)
     */
    private String metricType;
}
