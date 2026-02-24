package com.ljwx.platform.app;

import com.fasterxml.jackson.databind.ObjectMapper;
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
class MenuControllerIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
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
    void listMenus_unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/menus"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void listMenus_authenticated_returns200() throws Exception {
        mockMvc.perform(get("/api/v1/menus")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void getMenuTree_authenticated_returnsNestedStructure() throws Exception {
        mockMvc.perform(get("/api/v1/menus/tree")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void createMenu_missingRequiredFields_returns400() throws Exception {
        // missing parentId and menuType — both @NotNull
        String body = objectMapper.writeValueAsString(Map.of(
                "name", "TestMenu"
        ));
        mockMvc.perform(post("/api/v1/menus")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createAndDeleteMenu_fullCycle() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "parentId", 0,
                "name", "IT Test Menu",
                "menuType", 0,
                "sort", 99
        ));
        MvcResult createResult = mockMvc.perform(post("/api/v1/menus")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andReturn();
        Map<?, ?> createResp = objectMapper.readValue(createResult.getResponse().getContentAsString(), Map.class);
        Long menuId = ((Number) createResp.get("data")).longValue();
        assertThat(menuId).isPositive();

        mockMvc.perform(delete("/api/v1/menus/" + menuId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
    }

    @Test
    void getMenuById_nonExistent_returns4xx() throws Exception {
        mockMvc.perform(get("/api/v1/menus/999999999")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().is4xxClientError());
    }
}
