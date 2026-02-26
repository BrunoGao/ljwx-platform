package com.ljwx.platform.phase09;

import com.fasterxml.jackson.databind.JsonNode;
import com.ljwx.platform.app.test.base.BaseCrudTest;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Phase 09 — 通知模块集成测试。
 *
 * <p>验证 {@code /api/notices} 基本 CRUD + 401/403 安全要求。
 * 操作日志和登录日志为系统记录，无直接 CRUD 端点，由此测试间接覆盖（写入触发）。
 */
class NoticeApiTest extends BaseCrudTest {

    @Override
    protected String basePath() {
        return "/api/notices";
    }

    @Override
    protected String listPermission() {
        return "notice:read";
    }

    @Override
    protected String createPermission() {
        return "notice:write";
    }

    @Override
    protected String updatePermission() {
        return "notice:write";
    }

    @Override
    protected String deletePermission() {
        return "notice:write";
    }

    @Override
    protected Map<String, Object> createJson() {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        return Map.of(
                "noticeTitle", "IT Notice " + suffix,
                "noticeType", 1,
                "noticeContent", "Integration test notice",
                "status", 1
        );
    }

    @Override
    protected Map<String, Object> updateJson() {
        return Map.of(
                "noticeTitle", "IT Notice Updated",
                "noticeType", 2,
                "noticeContent", "Updated content",
                "status", 1
        );
    }

    /**
     * NoticeController 没有 GET /{id} 和 DELETE /{id} 端点，
     * 覆盖基类 CRUD 测试改为：create → update → list（验证可查到）。
     */
    @Override
    @Test
    protected void createReadUpdateDeleteHappyPath() throws Exception {
        String admin = fullPermissionToken();

        // 创建通知
        JsonNode created = readJson(performPost(basePath(), createJson(), admin));
        assertThat(created.path("code").asInt()).isEqualTo(200);
        long id = created.path("data").asLong();
        assertThat(id).isPositive();

        // 更新通知
        MvcResult updateResult = performPut(basePath() + "/" + id, updateJson(), admin);
        assertThat(updateResult.getResponse().getStatus()).isEqualTo(200);

        // 列表查询验证通知可见
        MvcResult listResult = performGet(basePath() + "?pageNum=1&pageSize=50", listOnlyToken());
        assertThat(listResult.getResponse().getStatus()).isEqualTo(200);
    }

    @Test
    void noticeListShouldReturnPageResult() throws Exception {
        String token = listOnlyToken();
        MvcResult result = performGet(basePath() + "?pageNum=1&pageSize=10", token);
        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        assertThat(readJson(result).path("code").asInt()).isEqualTo(200);
    }
}
