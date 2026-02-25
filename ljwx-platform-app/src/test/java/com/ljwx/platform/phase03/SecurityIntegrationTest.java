package com.ljwx.platform.phase03;

import com.fasterxml.jackson.databind.JsonNode;
import com.ljwx.platform.app.test.base.BaseIntegrationTest;
import com.ljwx.platform.app.test.security.ProtectedEndpointResolver;
import com.ljwx.platform.app.test.security.TestTokenHelper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MvcResult;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

class SecurityIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private ProtectedEndpointResolver endpointResolver;

    @Autowired
    private TestTokenHelper tokenHelper;

    private String protectedEndpoint;
    private String preAuthorizeExpression;

    @BeforeEach
    void setUp() {
        var resolved = endpointResolver.findPreAuthorizeGetEndpoint();
        protectedEndpoint = resolved.map(ProtectedEndpointResolver.ResolvedEndpoint::path)
                .orElse("/api/auth/me");
        preAuthorizeExpression = resolved.map(ProtectedEndpointResolver.ResolvedEndpoint::preAuthorize)
                .orElse("isAuthenticated()");
    }

    @Test
    void noTokenReturns401() throws Exception {
        MvcResult result = performGet(protectedEndpoint, null);
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void invalidTokenReturns401() throws Exception {
        MvcResult result = performGet(protectedEndpoint, "not-a-valid-jwt");
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void expiredTokenReturns401() throws Exception {
        MvcResult result = performGet(protectedEndpoint, tokenHelper.expiredToken());
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void validTokenReturnsSuccess() throws Exception {
        MvcResult result = performGet(protectedEndpoint, tokenHelper.adminTenantA());
        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        assertRCode(result, 200);
    }

    @Test
    void noPermissionTokenReturns403OnAuthorityProtectedEndpoint() throws Exception {
        assumeTrue(preAuthorizeExpression.contains("hasAuthority"),
                "No hasAuthority endpoint discovered; skip 403 permission assertion");
        MvcResult result = performGet(protectedEndpoint, tokenHelper.noPerm());
        assertThat(result.getResponse().getStatus()).isEqualTo(403);
    }

    @Test
    void tenantIsolationOnUserListByVisibility() throws Exception {
        assumeTrue(endpointResolver.hasEndpointPath("/api/users"),
                "Missing /api/users endpoint, pending future phase implementation");

        JsonNode tenantA = readJson(performGet("/api/users?pageNum=1&pageSize=100", tokenHelper.userTenantA()));
        JsonNode tenantB = readJson(performGet("/api/users?pageNum=1&pageSize=100", tokenHelper.adminTenantB()));

        long totalA = tenantA.path("data").path("total").asLong();
        long totalB = tenantB.path("data").path("total").asLong();

        assertThat(totalA).isGreaterThanOrEqualTo(1L);
        assertThat(totalB).isGreaterThanOrEqualTo(1L);

        boolean tenantAContainsTenantBUser = false;
        for (JsonNode row : tenantA.path("data").path("rows")) {
            if ("tenant_b_user".equals(row.path("username").asText())) {
                tenantAContainsTenantBUser = true;
                break;
            }
        }
        boolean tenantBContainsAdmin = false;
        for (JsonNode row : tenantB.path("data").path("rows")) {
            if ("admin".equals(row.path("username").asText())) {
                tenantBContainsAdmin = true;
                break;
            }
        }

        assertThat(tenantAContainsTenantBUser).isFalse();
        assertThat(tenantBContainsAdmin).isFalse();
    }
}
