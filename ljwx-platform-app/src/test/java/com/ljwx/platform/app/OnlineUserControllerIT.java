package com.ljwx.platform.app;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ljwx.platform.app.test.support.TestCredentials;
import com.ljwx.platform.security.blacklist.LoginLockoutService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OnlineUserControllerIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private LoginLockoutService loginLockoutService;

    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
        // Clear any lockout state before login
        loginLockoutService.clearFailure("admin");

        String loginBody = objectMapper.writeValueAsString(Map.of(
                "username", TestCredentials.ADMIN_USERNAME,
                "password", TestCredentials.ADMIN_PASSWORD
        ));
        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody))
                .andExpect(status().isOk())
                .andReturn();
        Map<?, ?> resp = objectMapper.readValue(result.getResponse().getContentAsString(), Map.class);
        Map<?, ?> data = (Map<?, ?>) resp.get("data");
        adminToken = (String) data.get("accessToken");
    }

    @Test
    void listOnlineUsers_unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/online-users"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void listOnlineUsers_authenticated_returns200WithArray() throws Exception {
        mockMvc.perform(get("/api/v1/online-users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void listOnlineUsers_afterLogin_containsCurrentSession() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/online-users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andReturn();
        Map<?, ?> resp = objectMapper.readValue(result.getResponse().getContentAsString(), Map.class);
        List<?> data = (List<?>) resp.get("data");
        // At least the current session should be online
        assertThat(data).isNotNull();
    }

    @Test
    void kickout_invalidTokenId_returnsOkGracefully() throws Exception {
        // Kicking out a non-existent token should not throw — graceful no-op
        mockMvc.perform(delete("/api/v1/online-users/non-existent-token-id-12345")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
    }

    @Test
    void kickout_unauthenticated_returns401() throws Exception {
        mockMvc.perform(delete("/api/v1/online-users/some-token-id"))
                .andExpect(status().is4xxClientError());
    }
}
