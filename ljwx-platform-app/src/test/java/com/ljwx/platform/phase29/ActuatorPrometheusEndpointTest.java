package com.ljwx.platform.phase29;

import com.ljwx.platform.app.test.base.BaseIntegrationTest;
import com.ljwx.platform.app.test.security.TestTokenHelper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Validates actuator Prometheus endpoint behavior for observability scraping.
 */
class ActuatorPrometheusEndpointTest extends BaseIntegrationTest {

    @Autowired
    private TestTokenHelper tokenHelper;

    @Test
    void prometheusEndpointShouldAllowAnonymousAccessAndKeepRawPayload() throws Exception {
        var result = performGet("/actuator/prometheus", null);

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        assertThat(result.getResponse().getContentType()).contains("text/plain");
        assertThat(result.getResponse().getContentAsString()).contains("# HELP");
        assertThat(result.getResponse().getContentAsString()).doesNotContain("\"code\":200");
    }

    @Test
    void prometheusEndpointShouldNotBeWrappedWhenAuthenticated() throws Exception {
        String token = tokenHelper.adminTenantA();
        var result = performGet("/actuator/prometheus", token);

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        assertThat(result.getResponse().getContentType()).contains("text/plain");
        assertThat(result.getResponse().getContentAsString()).contains("# TYPE");
        assertThat(result.getResponse().getContentAsString()).doesNotContain("\"code\":200");
    }
}
