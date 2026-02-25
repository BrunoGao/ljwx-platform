package com.ljwx.platform.phase00;

import com.ljwx.platform.app.test.base.BaseIntegrationTest;
import com.ljwx.platform.app.test.security.TestTokenHelper;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MvcResult;

import static org.assertj.core.api.Assertions.assertThat;

class SmokeTest extends BaseIntegrationTest {

    @Autowired
    private Flyway flyway;

    @Autowired
    private TestTokenHelper tokenHelper;

    @Test
    void contextStartsAndFlywayApplied() {
        assertThat(flyway.info().applied()).isNotEmpty();
    }

    @Test
    void generatedTokenCanPassAuthenticationFilter() throws Exception {
        String token = tokenHelper.userTenantA();
        MvcResult result = performGet("/api/auth/me", token);
        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        assertRCode(result, 200);
    }
}
