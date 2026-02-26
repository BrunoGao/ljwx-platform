package com.ljwx.platform.phase28;

import com.ljwx.platform.app.test.base.BaseIntegrationTest;
import com.ljwx.platform.app.test.security.TestTokenHelper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Phase 28 — 安全加固集成测试。
 *
 * <p>验证 XSS 过滤、请求授权规则等基础安全能力：
 * <ul>
 *   <li>XSS 过滤不阻断正常 GET 请求（非预期转义下仍返回 200）</li>
 *   <li>受保护端点无 token → 401</li>
 *   <li>受保护端点无权限 → 403</li>
 * </ul>
 */
class SecurityHardeningApiTest extends BaseIntegrationTest {

    @Autowired
    private TestTokenHelper tokenHelper;

    @Test
    void protectedEndpointWithoutTokenReturns401() throws Exception {
        var result = performGet("/api/dicts?pageNum=1&pageSize=10", null);
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void protectedEndpointWithNoPermReturns403() throws Exception {
        String token = tokenHelper.generateToken(1L, "admin", 1L, List.of(), 1800L);
        var result = performGet("/api/dicts?pageNum=1&pageSize=10", token);
        assertThat(result.getResponse().getStatus()).isEqualTo(403);
    }

    @Test
    void xssCharactersInQueryParamShouldNotBreakRequest() throws Exception {
        // XssFilter 应转义参数后放行，接口因无权限返回 403（而非因 XSS 导致 500）
        String token = tokenHelper.generateToken(1L, "admin", 1L, List.of(), 1800L);
        var result = performGet("/api/dicts?pageNum=1&pageSize=10&dictType=<script>alert(1)</script>", token);
        // 有 XssFilter 时：参数被转义，返回 403（权限不足）而非 500
        assertThat(result.getResponse().getStatus()).isIn(403, 200);
    }

    @Test
    void validTokenWithPermissionShouldAccessProtectedEndpoint() throws Exception {
        String token = tokenHelper.generateToken(1L, "admin", 1L, List.of("dict:read"), 1800L);
        var result = performGet("/api/dicts?pageNum=1&pageSize=10", token);
        assertThat(result.getResponse().getStatus()).isEqualTo(200);
    }
}
