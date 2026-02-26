package com.ljwx.platform.app.test.base;

import com.fasterxml.jackson.databind.JsonNode;
import com.ljwx.platform.app.test.security.TestTokenHelper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Reusable CRUD test template for phase-based API tests.
 */
public abstract class BaseCrudTest extends BaseIntegrationTest {

    @Autowired
    protected TestTokenHelper tokenHelper;

    protected abstract String basePath();

    protected abstract String listPermission();

    protected String detailPermission() {
        return listPermission();
    }

    protected abstract String createPermission();

    protected abstract String updatePermission();

    protected abstract String deletePermission();

    protected abstract Map<String, Object> createJson();

    protected abstract Map<String, Object> updateJson();

    protected String idFieldName() {
        return "data";
    }

    protected String fullPermissionToken() {
        return tokenHelper.generateToken(
                1L,
                "admin",
                1L,
                java.util.List.of(listPermission(), createPermission(), updatePermission(), deletePermission()),
                1800L);
    }

    protected String listOnlyToken() {
        return tokenHelper.generateToken(1L, "admin", 1L, java.util.List.of(listPermission()), 1800L);
    }

    @Test
    void unauthorizedShouldReturn401() throws Exception {
        MvcResult result = performGet(basePath(), null);
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void forbiddenShouldReturn403() throws Exception {
        MvcResult result = performGet(basePath(), tokenHelper.noPerm());
        assertThat(result.getResponse().getStatus()).isEqualTo(403);
    }

    @Test
    protected void createReadUpdateDeleteHappyPath() throws Exception {
        String admin = fullPermissionToken();

        JsonNode created = readJson(performPost(basePath(), createJson(), admin));
        assertThat(created.path("code").asInt()).isEqualTo(200);
        long id = created.path(idFieldName()).asLong();
        assertThat(id).isPositive();

        MvcResult getResult = performGet(
                basePath() + "/" + id,
                tokenHelper.generateToken(
                        1L,
                        "admin",
                        1L,
                        java.util.List.of(detailPermission()),
                        1800L));
        assertThat(getResult.getResponse().getStatus()).isEqualTo(200);

        MvcResult updateResult = performPut(basePath() + "/" + id, updateJson(), admin);
        assertThat(updateResult.getResponse().getStatus()).isEqualTo(200);

        MvcResult deleteResult = performDelete(basePath() + "/" + id, admin);
        assertThat(deleteResult.getResponse().getStatus()).isEqualTo(200);
    }

    @Test
    void validationFailureShouldReturn400() throws Exception {
        MvcResult result = performPost(basePath(), Map.of(), fullPermissionToken());
        assertThat(result.getResponse().getStatus()).isEqualTo(400);
    }
}
