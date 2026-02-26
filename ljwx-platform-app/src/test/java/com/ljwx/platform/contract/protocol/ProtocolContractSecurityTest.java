package com.ljwx.platform.contract.protocol;

import com.fasterxml.jackson.databind.JsonNode;
import com.ljwx.platform.app.test.base.BaseIntegrationTest;
import com.ljwx.platform.app.test.security.ProtocolEndpointResolver;
import com.ljwx.platform.app.test.security.TestTokenHelper;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Protocol-level security contract:
 * - protected endpoints without token return 401 with R envelope
 * - hasAuthority endpoints with no-permission token return 403 with R envelope
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ProtocolContractSecurityTest extends BaseIntegrationTest {

    @Autowired
    private ProtocolEndpointResolver endpointResolver;

    @Autowired
    private TestTokenHelper tokenHelper;

    private List<ProtocolEndpointResolver.ProtocolEndpoint> protectedEndpoints;
    private List<ProtocolEndpointResolver.ProtocolEndpoint> authorityEndpoints;

    @BeforeAll
    void setUpEndpoints() {
        protectedEndpoints = endpointResolver.protectedGetEndpoints();
        authorityEndpoints = protectedEndpoints.stream()
                .filter(ProtocolEndpointResolver.ProtocolEndpoint::hasAuthority)
                .toList();

        assertThat(protectedEndpoints)
                .as("protected endpoint catalog must not be empty")
                .isNotEmpty();
        assertThat(authorityEndpoints)
                .as("hasAuthority endpoint catalog must not be empty")
                .isNotEmpty();
    }

    Stream<ProtocolEndpointResolver.ProtocolEndpoint> protectedEndpoints() {
        return protectedEndpoints.stream();
    }

    Stream<ProtocolEndpointResolver.ProtocolEndpoint> authorityEndpoints() {
        return authorityEndpoints.stream();
    }

    @ParameterizedTest(name = "[401] {0}")
    @MethodSource("protectedEndpoints")
    void protectedEndpointWithoutTokenReturns401(ProtocolEndpointResolver.ProtocolEndpoint endpoint) throws Exception {
        MvcResult result = performGet(endpoint.path(), null);
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
        assertEnvelope(result);
    }

    @ParameterizedTest(name = "[403] {0}")
    @MethodSource("authorityEndpoints")
    void authorityEndpointWithNoPermissionTokenReturns403(ProtocolEndpointResolver.ProtocolEndpoint endpoint) throws Exception {
        MvcResult result = performGet(endpoint.path(), tokenHelper.noPerm());
        assertThat(result.getResponse().getStatus()).isEqualTo(403);
        assertEnvelope(result);
    }

    private void assertEnvelope(MvcResult result) throws Exception {
        JsonNode body = readJson(result);
        assertThat(body.has("code")).isTrue();
        assertThat(body.has("message")).isTrue();
        assertThat(body.has("data")).isTrue();
        assertThat(body.path("code").isNumber()).isTrue();
        assertThat(body.path("message").asText()).isNotBlank();
    }
}
