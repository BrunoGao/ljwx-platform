package com.ljwx.platform.phase20;

import com.ljwx.platform.app.test.base.BaseCrudTest;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class MenuApiIntegrationTest extends BaseCrudTest {

    @Override
    protected String basePath() {
        return "/api/v1/menus";
    }

    @Override
    protected String listPermission() {
        return "system:menu:list";
    }

    @Override
    protected String createPermission() {
        return "system:menu:create";
    }

    @Override
    protected String updatePermission() {
        return "system:menu:update";
    }

    @Override
    protected String deletePermission() {
        return "system:menu:delete";
    }

    @Override
    protected Map<String, Object> createJson() {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        return Map.of(
                "parentId", 0,
                "name", "IT Menu " + suffix,
                "menuType", 1,
                "path", "/it-" + suffix,
                "component", "system/it/index",
                "sort", 99,
                "visible", 1,
                "permission", "it:menu:" + suffix
        );
    }

    @Override
    protected Map<String, Object> updateJson() {
        return Map.of(
                "name", "IT Menu Updated",
                "sort", 100,
                "visible", 1,
                "menuType", 1
        );
    }

    @Test
    void menuTreeShouldReturnArray() throws Exception {
        var result = performGet("/api/v1/menus/tree", listOnlyToken());
        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        assertThat(readJson(result).path("data").isArray()).isTrue();
    }
}
