package com.ljwx.platform.app.service;

import com.ljwx.platform.app.config.BootstrapPasswordProperties;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import com.ljwx.platform.web.validator.StrongPasswordValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

/**
 * Centralizes bootstrap and fallback password handling.
 */
@Service
@RequiredArgsConstructor
public class BootstrapPasswordService {

    public static final String BOOTSTRAP_ADMIN_USERNAME = "admin";
    public static final String LEGACY_DEFAULT_ADMIN_PASSWORD_HASH =
            "$2a$10$PnWlMR8Ox6UMTZj7Zm9uO.wSqzbjVt04UbeJ7q3RxDe8TSIP6efz2";
    public static final String MANAGED_PLACEHOLDER_ADMIN_PASSWORD_HASH =
            "$2b$10$uCp2Sw/d8Ipq5FrRNfBUt.FOq8dszFY/XHDumEDk3u5IhrZz1JW9S";

    private static final StrongPasswordValidator STRONG_PASSWORD_VALIDATOR = new StrongPasswordValidator();

    private final BootstrapPasswordProperties properties;

    /**
     * Resolve the configured bootstrap admin password for tenant initialization flows.
     */
    public String requireAdminInitialPassword() {
        return normalizeAndValidate(
                properties.getAdminInitialPassword(),
                () -> new BusinessException(
                        ErrorCode.SYSTEM_ERROR,
                        "未配置租户初始化管理员密码，请设置环境变量 LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD"
                ),
                () -> new BusinessException(
                        ErrorCode.SYSTEM_ERROR,
                        "环境变量 LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD 不符合强密码策略"
                )
        );
    }

    /**
     * Resolve the configured bootstrap admin password during application startup.
     */
    public String requireAdminInitialPasswordForStartup() {
        return normalizeAndValidate(
                properties.getAdminInitialPassword(),
                () -> new IllegalStateException(
                        "检测到待引导管理员账号，请设置环境变量 LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD 后重启应用"
                ),
                () -> new IllegalStateException(
                        "环境变量 LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD 不符合强密码策略"
                )
        );
    }

    /**
     * Resolve a password for imported users, rejecting blank or weak values.
     *
     * @param providedPassword password from the import file
     * @param rowNumber        1-based row number for error reporting
     * @return normalized strong password
     */
    public String resolveImportedUserPassword(String providedPassword, int rowNumber) {
        if (StringUtils.hasText(providedPassword)) {
            return normalizeAndValidate(
                    providedPassword,
                    () -> new BusinessException(
                            ErrorCode.PARAM_VALIDATION_FAILED,
                            "导入文件第 " + rowNumber + " 行缺少初始密码"
                    ),
                    () -> new BusinessException(
                            ErrorCode.PARAM_VALIDATION_FAILED,
                            "导入文件第 " + rowNumber + " 行密码不符合强密码策略"
                    )
            );
        }

        return normalizeAndValidate(
                properties.getUserImportInitialPassword(),
                () -> new BusinessException(
                        ErrorCode.PARAM_VALIDATION_FAILED,
                        "导入文件第 " + rowNumber + " 行缺少初始密码，请在文件中提供密码或设置环境变量 LJWX_BOOTSTRAP_USER_IMPORT_INITIAL_PASSWORD"
                ),
                () -> new BusinessException(
                        ErrorCode.SYSTEM_ERROR,
                        "环境变量 LJWX_BOOTSTRAP_USER_IMPORT_INITIAL_PASSWORD 不符合强密码策略"
                )
        );
    }

    private String normalizeAndValidate(
            String password,
            RuntimeExceptionSupplier missingExceptionSupplier,
            RuntimeExceptionSupplier weakExceptionSupplier
    ) {
        if (!StringUtils.hasText(password)) {
            throw missingExceptionSupplier.get();
        }

        String normalized = password.trim();
        if (!STRONG_PASSWORD_VALIDATOR.isValid(normalized, null)) {
            throw weakExceptionSupplier.get();
        }

        return normalized;
    }

    @FunctionalInterface
    private interface RuntimeExceptionSupplier {
        RuntimeException get();
    }
}
