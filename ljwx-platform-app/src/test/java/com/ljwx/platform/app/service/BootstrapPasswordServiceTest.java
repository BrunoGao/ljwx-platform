package com.ljwx.platform.app.service;

import com.ljwx.platform.app.config.BootstrapPasswordProperties;
import com.ljwx.platform.web.exception.BusinessException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class BootstrapPasswordServiceTest {

    @Test
    void requireAdminInitialPasswordReturnsTrimmedConfiguredValue() {
        BootstrapPasswordProperties properties = new BootstrapPasswordProperties();
        properties.setAdminInitialPassword("  TestSecure#2026A  ");

        BootstrapPasswordService service = new BootstrapPasswordService(properties);

        assertEquals("TestSecure#2026A", service.requireAdminInitialPassword());
    }

    @Test
    void requireAdminInitialPasswordRejectsBlankConfig() {
        BootstrapPasswordProperties properties = new BootstrapPasswordProperties();
        BootstrapPasswordService service = new BootstrapPasswordService(properties);

        BusinessException exception = assertThrows(
                BusinessException.class,
                service::requireAdminInitialPassword
        );

        assertEquals(
                "未配置租户初始化管理员密码，请设置环境变量 LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD",
                exception.getMessage()
        );
    }

    @Test
    void requireAdminInitialPasswordForStartupRejectsWeakConfig() {
        BootstrapPasswordProperties properties = new BootstrapPasswordProperties();
        properties.setAdminInitialPassword("weakpass");

        BootstrapPasswordService service = new BootstrapPasswordService(properties);

        IllegalStateException exception = assertThrows(
                IllegalStateException.class,
                service::requireAdminInitialPasswordForStartup
        );

        assertEquals(
                "环境变量 LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD 不符合强密码策略",
                exception.getMessage()
        );
    }

    @Test
    void resolveImportedUserPasswordUsesProvidedPasswordBeforeFallback() {
        BootstrapPasswordProperties properties = new BootstrapPasswordProperties();
        properties.setUserImportInitialPassword("ImportSecure#2026A");

        BootstrapPasswordService service = new BootstrapPasswordService(properties);

        assertEquals(
                "RowPassword#2026A",
                service.resolveImportedUserPassword("RowPassword#2026A", 3)
        );
    }

    @Test
    void resolveImportedUserPasswordFallsBackToConfiguredImportPassword() {
        BootstrapPasswordProperties properties = new BootstrapPasswordProperties();
        properties.setUserImportInitialPassword("ImportSecure#2026A");

        BootstrapPasswordService service = new BootstrapPasswordService(properties);

        assertEquals(
                "ImportSecure#2026A",
                service.resolveImportedUserPassword("   ", 5)
        );
    }

    @Test
    void resolveImportedUserPasswordRejectsMissingPasswordWhenNoFallbackExists() {
        BootstrapPasswordProperties properties = new BootstrapPasswordProperties();
        BootstrapPasswordService service = new BootstrapPasswordService(properties);

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.resolveImportedUserPassword(null, 7)
        );

        assertEquals(
                "导入文件第 7 行缺少初始密码，请在文件中提供密码或设置环境变量 LJWX_BOOTSTRAP_USER_IMPORT_INITIAL_PASSWORD",
                exception.getMessage()
        );
    }
}
