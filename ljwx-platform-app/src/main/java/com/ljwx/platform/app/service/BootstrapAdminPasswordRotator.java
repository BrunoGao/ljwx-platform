package com.ljwx.platform.app.service;

import com.ljwx.platform.app.infra.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Rotates managed bootstrap admin hashes to the configured runtime secret.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BootstrapAdminPasswordRotator implements ApplicationRunner {

    private final SysUserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final BootstrapPasswordService bootstrapPasswordService;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        long legacyCount = userMapper.countByUsernameAndPassword(
                BootstrapPasswordService.BOOTSTRAP_ADMIN_USERNAME,
                BootstrapPasswordService.LEGACY_DEFAULT_ADMIN_PASSWORD_HASH
        );
        long placeholderCount = userMapper.countByUsernameAndPassword(
                BootstrapPasswordService.BOOTSTRAP_ADMIN_USERNAME,
                BootstrapPasswordService.MANAGED_PLACEHOLDER_ADMIN_PASSWORD_HASH
        );

        if (legacyCount + placeholderCount == 0) {
            return;
        }

        String configuredPassword = bootstrapPasswordService.requireAdminInitialPasswordForStartup();
        String encodedPassword = passwordEncoder.encode(configuredPassword);

        int rotatedLegacy = userMapper.updatePasswordByUsernameAndPassword(
                BootstrapPasswordService.BOOTSTRAP_ADMIN_USERNAME,
                BootstrapPasswordService.LEGACY_DEFAULT_ADMIN_PASSWORD_HASH,
                encodedPassword
        );
        int rotatedPlaceholder = userMapper.updatePasswordByUsernameAndPassword(
                BootstrapPasswordService.BOOTSTRAP_ADMIN_USERNAME,
                BootstrapPasswordService.MANAGED_PLACEHOLDER_ADMIN_PASSWORD_HASH,
                encodedPassword
        );

        int totalRotated = rotatedLegacy + rotatedPlaceholder;
        if (totalRotated > 0) {
            log.warn(
                    "已轮换 {} 个受管引导管理员账号的初始密码，请在首次登录后强制修改密码。",
                    totalRotated
            );
        }
    }
}
