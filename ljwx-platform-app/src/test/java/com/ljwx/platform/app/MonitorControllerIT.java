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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MonitorControllerIT {

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
    void serverInfo_unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/monitor/server"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void serverInfo_authenticated_returns200WithData() throws Exception {
        mockMvc.perform(get("/api/v1/monitor/server")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").exists())
                .andExpect(jsonPath("$.data.osName").exists());
    }

    @Test
    void jvmInfo_authenticated_returns200WithHeapData() throws Exception {
        mockMvc.perform(get("/api/v1/monitor/jvm")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").exists())
                .andExpect(jsonPath("$.data.heapUsed").exists());
    }

    @Test
    void cacheInfo_authenticated_returns200WithArray() throws Exception {
        mockMvc.perform(get("/api/v1/monitor/cache")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void jvmInfo_unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/monitor/jvm"))
                .andExpect(status().is4xxClientError());
    }
}
