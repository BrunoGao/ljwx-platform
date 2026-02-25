package com.ljwx.platform.phase08;

import com.ljwx.platform.app.test.base.BaseIntegrationTest;
import com.ljwx.platform.app.test.security.TestTokenHelper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class DictConfigApiTest extends BaseIntegrationTest {

    @Autowired
    private TestTokenHelper tokenHelper;

    @Test
    void dictListShouldRequireAuth() throws Exception {
        var result = performGet("/api/dicts", null);
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void dictCrudCoreFlow() throws Exception {
        String rw = tokenHelper.generateToken(1L, "admin", 1L, List.of("dict:read", "dict:write"), 1800);

        String suffix = UUID.randomUUID().toString().substring(0, 8);
        var create = performPost("/api/dicts", Map.of(
                "dictName", "IT Dict " + suffix,
                "dictType", "it_dict_" + suffix
        ), rw);
        assertThat(create.getResponse().getStatus()).isEqualTo(200);
        long id = readJson(create).path("data").asLong();
        assertThat(id).isPositive();

        var update = performPut("/api/dicts/" + id, Map.of(
                "dictName", "IT Dict Updated",
                "dictType", "it_dict_" + suffix,
                "version", 1
        ), rw);
        assertThat(update.getResponse().getStatus()).isEqualTo(200);

        var list = performGet("/api/dicts?pageNum=1&pageSize=20", rw);
        assertThat(list.getResponse().getStatus()).isEqualTo(200);
    }

    @Test
    void configCrudCoreFlow() throws Exception {
        String rw = tokenHelper.generateToken(1L, "admin", 1L, List.of("config:read", "config:write"), 1800);

        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String key = "it.config." + suffix;
        var create = performPost("/api/configs", Map.of(
                "configName", "IT Config " + suffix,
                "configKey", key,
                "configValue", "v1"
        ), rw);
        assertThat(create.getResponse().getStatus()).isEqualTo(200);
        long id = readJson(create).path("data").asLong();
        assertThat(id).isPositive();

        var update = performPut("/api/configs/" + id, Map.of(
                "configName", "IT Config Updated",
                "configKey", key,
                "configValue", "v2",
                "version", 1
        ), rw);
        assertThat(update.getResponse().getStatus()).isEqualTo(200);

        var byKey = performGet("/api/configs/key/" + key, rw);
        assertThat(byKey.getResponse().getStatus()).isEqualTo(200);
    }
}
