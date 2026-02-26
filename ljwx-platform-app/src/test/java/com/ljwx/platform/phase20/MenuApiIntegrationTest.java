package com.ljwx.platform.phase20;

import com.ljwx.platform.app.test.base.BaseCrudTest;
import com.fasterxml.jackson.databind.JsonNode;
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

    @Test
    void deleteMenuWithChildrenShouldReturn400() throws Exception {
        String admin = fullPermissionToken();
        // 创建父菜单
        JsonNode parentResp = readJson(performPost(basePath(), Map.of(
                "parentId", 0, "name", "Parent Menu", "menuType", 0,
                "path", "/parent", "component", "Layout", "sort", 50,
                "visible", 1, "permission", ""), admin));
        long parentId = parentResp.path("data").asLong();
        assertThat(parentId).isPositive();

        // 创建子菜单
        JsonNode childResp = readJson(performPost(basePath(), Map.of(
                "parentId", parentId, "name", "Child Menu", "menuType", 1,
                "path", "/parent/child", "component", "parent/child/index",
                "sort", 1, "visible", 1, "permission", ""), admin));
        assertThat(childResp.path("code").asInt()).isEqualTo(200);

        // 尝试删除父菜单 → 期望 400
        var deleteResult = performDelete(basePath() + "/" + parentId, admin);
        assertThat(deleteResult.getResponse().getStatus()).isEqualTo(400);
    }

    @Test
    void createMenuWithNonExistentParentShouldReturn400() throws Exception {
        var result = performPost(basePath(), Map.of(
                "parentId", 99999999L, "name", "Orphan Menu", "menuType", 1,
                "path", "/orphan", "component", "orphan/index",
                "sort", 1, "visible", 1, "permission", ""), fullPermissionToken());
        assertThat(result.getResponse().getStatus()).isEqualTo(400);
    }
}
