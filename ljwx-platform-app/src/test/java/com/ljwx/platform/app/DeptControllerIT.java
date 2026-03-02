package com.ljwx.platform.app;

import com.fasterxml.jackson.databind.ObjectMapper;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class DeptControllerIT {

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
                "username", "admin",
                "password", "Admin@12345"
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
    void listDepts_unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/depts"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void listDepts_authenticated_returns200() throws Exception {
        mockMvc.perform(get("/api/v1/depts")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void getDeptTree_authenticated_returnsArray() throws Exception {
        mockMvc.perform(get("/api/v1/depts/tree")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void createDept_missingRequiredFields_returns400() throws Exception {
        // missing parentId (@NotNull) and name (@NotBlank)
        String body = objectMapper.writeValueAsString(Map.of(
                "sort", 1
        ));
        mockMvc.perform(post("/api/v1/depts")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createAndDeleteDept_fullCycle() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "parentId", 0,
                "name", "IT Test Dept",
                "sort", 99
        ));
        MvcResult createResult = mockMvc.perform(post("/api/v1/depts")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andReturn();
        Map<?, ?> createResp = objectMapper.readValue(createResult.getResponse().getContentAsString(), Map.class);
        Long deptId = ((Number) createResp.get("data")).longValue();
        assertThat(deptId).isPositive();

        mockMvc.perform(delete("/api/v1/depts/" + deptId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
    }

    @Test
    void getDeptById_nonExistent_returns4xx() throws Exception {
        mockMvc.perform(get("/api/v1/depts/999999999")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().is4xxClientError());
    }
}
