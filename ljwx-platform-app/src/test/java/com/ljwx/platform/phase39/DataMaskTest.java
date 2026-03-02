package com.ljwx.platform.phase39;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ljwx.platform.app.domain.vo.UserVO;
import com.ljwx.platform.core.security.MaskType;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;

import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Phase 39 — 数据脱敏测试
 */
@SpringBootTest(classes = com.ljwx.platform.app.LjwxPlatformApplication.class)
@ActiveProfiles("test")
class DataMaskTest {

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testPhoneMasking() throws Exception {
        // Given
        UserVO user = new UserVO();
        user.setId(1L);
        user.setUsername("testuser");
        user.setPhone("13812345678");

        // When - no unmask permission
        SecurityContextHolder.clearContext();
        String json = objectMapper.writeValueAsString(user);

        // Then
        assertThat(json).contains("138****5678");
        assertThat(json).doesNotContain("13812345678");
    }

    @Test
    void testEmailMasking() throws Exception {
        // Given
        UserVO user = new UserVO();
        user.setId(1L);
        user.setUsername("testuser");
        user.setEmail("zhangsan@example.com");

        // When - no unmask permission
        SecurityContextHolder.clearContext();
        String json = objectMapper.writeValueAsString(user);

        // Then
        assertThat(json).contains("zh***@example.com");
        assertThat(json).doesNotContain("zhangsan@example.com");
    }

    @Test
    void testUnmaskWithPermission() throws Exception {
        // Given
        UserVO user = new UserVO();
        user.setId(1L);
        user.setUsername("testuser");
        user.setPhone("13812345678");
        user.setEmail("zhangsan@example.com");

        // When - with unmask permission
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                "admin",
                null,
                Collections.singletonList(new SimpleGrantedAuthority("system:data:unmask"))
        );
        SecurityContextHolder.getContext().setAuthentication(auth);

        String json = objectMapper.writeValueAsString(user);

        // Then - should not be masked
        assertThat(json).contains("13812345678");
        assertThat(json).contains("zhangsan@example.com");

        // Cleanup
        SecurityContextHolder.clearContext();
    }
}
