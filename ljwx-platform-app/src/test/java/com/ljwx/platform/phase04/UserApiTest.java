package com.ljwx.platform.phase04;

import com.ljwx.platform.app.test.base.BaseCrudTest;
import com.ljwx.platform.app.test.support.TestCredentials;

import java.util.Map;
import java.util.UUID;

class UserApiTest extends BaseCrudTest {

    @Override
    protected String basePath() {
        return "/api/users";
    }

    @Override
    protected String listPermission() {
        return "user:read";
    }

    @Override
    protected String createPermission() {
        return "user:write";
    }

    @Override
    protected String updatePermission() {
        return "user:write";
    }

    @Override
    protected String deletePermission() {
        return "user:delete";
    }

    @Override
    protected Map<String, Object> createJson() {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        return Map.of(
                "username", "it_user_" + suffix,
                "password", TestCredentials.USER_CREATE_PASSWORD,
                "nickname", "IT User " + suffix
        );
    }

    @Override
    protected Map<String, Object> updateJson() {
        return Map.of(
                "nickname", "Updated User",
                "email", "updated@example.com",
                "status", 1
        );
    }
}
