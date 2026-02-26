package com.ljwx.platform.phase30;

import com.ljwx.platform.app.test.base.BaseIntegrationTest;
import com.ljwx.platform.app.test.security.TestTokenHelper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Phase 30 — 数据变更审计日志集成测试。
 *
 * <p>验证 {@code GET /api/v1/data-change-logs} 的权限控制与基本查询：
 * <ul>
 *   <li>无 token → 401</li>
 *   <li>无权限 → 403</li>
 *   <li>有 system:audit:list 权限 → 200，返回分页结构</li>
 * </ul>
 */
class DataChangeLogApiTest extends BaseIntegrationTest {

    private static final String PATH = "/api/v1/data-change-logs";

    @Autowired
    private TestTokenHelper tokenHelper;

    @Test
    void withoutTokenReturns401() throws Exception {
        var result = performGet(PATH, null);
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void withoutPermissionReturns403() throws Exception {
        String token = tokenHelper.generateToken(1L, "admin", 1L, List.of(), 1800L);
        var result = performGet(PATH, token);
        assertThat(result.getResponse().getStatus()).isEqualTo(403);
    }

    @Test
    void withAuditPermissionReturns200() throws Exception {
        String token = tokenHelper.generateToken(1L, "admin", 1L, List.of("system:audit:list"), 1800L);
        var result = performGet(PATH + "?pageNum=1&pageSize=10", token);
        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        assertThat(readJson(result).path("code").asInt()).isEqualTo(200);
    }

    @Test
    void queryByTableNameShouldReturn200() throws Exception {
        String token = tokenHelper.generateToken(1L, "admin", 1L, List.of("system:audit:list"), 1800L);
        var result = performGet(PATH + "?tableName=sys_user&pageNum=1&pageSize=5", token);
        assertThat(result.getResponse().getStatus()).isEqualTo(200);
    }
}
