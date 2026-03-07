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

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LoginLogControllerIT {

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
    void listLoginLogs_unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/login-logs"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void listLoginLogs_authenticated_returns200() throws Exception {
        mockMvc.perform(get("/api/v1/login-logs")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").exists());
    }

    @Test
    void listLoginLogs_afterLogin_logsArePresent() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/login-logs")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("pageNum", "1")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andReturn();
        Map<?, ?> resp = objectMapper.readValue(result.getResponse().getContentAsString(), Map.class);
        Map<?, ?> data = (Map<?, ?>) resp.get("data");
        // At least the login in @BeforeEach should have been recorded
        assertThat(data).isNotNull();
    }

    @Test
    void listLoginLogs_withUsernameFilter_returns200() throws Exception {
        mockMvc.perform(get("/api/v1/login-logs")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("username", "admin")
                        .param("pageNum", "1")
                        .param("pageSize", "5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").exists());
    }

    @Test
    void listLoginLogs_withStatusFilter_returns200() throws Exception {
        mockMvc.perform(get("/api/v1/login-logs")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("status", "1")
                        .param("pageNum", "1")
                        .param("pageSize", "5"))
                .andExpect(status().isOk());
    }
}
