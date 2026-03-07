package com.ljwx.platform.app.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Bootstrap password configuration sourced from environment variables.
 */
@Data
@Component
@ConfigurationProperties(prefix = "ljwx.bootstrap")
public class BootstrapPasswordProperties {

    /**
     * Initial password used when bootstrapping the tenant admin account.
     */
    private String adminInitialPassword = "";

    /**
     * Fallback password for user import rows that omit the password column.
     */
    private String userImportInitialPassword = "";
}
