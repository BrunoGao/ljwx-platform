package com.ljwx.platform.app.test.base;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ljwx.platform.app.LjwxPlatformApplication;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.containers.PostgreSQLContainer;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

/**
 * Shared integration test base.
 *
 * <p>Uses PostgreSQL Testcontainers to stay aligned with production SQL and Flyway dialect.
 */
@SpringBootTest(
        classes = LjwxPlatformApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Transactional
public abstract class BaseIntegrationTest {

    static final PostgreSQLContainer<?> POSTGRES = createPostgresContainer();

    private static PostgreSQLContainer<?> createPostgresContainer() {
        try {
            if (DockerClientFactory.instance().isDockerAvailable()) {
                return new PostgreSQLContainer<>("postgres:16.12-alpine")
                        .withDatabaseName("ljwx_test")
                        .withUsername("ljwx")
                        .withPassword("ljwx");
            }
        } catch (RuntimeException ignored) {
            // Fallback to local postgres when docker is unavailable.
        }
        return null;
    }

    @BeforeAll
    void startPostgresIfNeeded() {
        if (POSTGRES != null && !POSTGRES.isRunning()) {
            POSTGRES.start();
        }
    }

    @AfterAll
    void stopPostgresIfNeeded() {
        if (POSTGRES != null && POSTGRES.isRunning()) {
            POSTGRES.stop();
        }
    }

    @DynamicPropertySource
    static void registerDatasource(DynamicPropertyRegistry registry) {
        if (POSTGRES != null) {
            registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
            registry.add("spring.datasource.username", POSTGRES::getUsername);
            registry.add("spring.datasource.password", POSTGRES::getPassword);
            registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
            return;
        }

        registry.add("spring.datasource.url", () -> "jdbc:postgresql://127.0.0.1:5432/ljwx_platform");
        registry.add("spring.datasource.username", () -> "postgres");
        registry.add("spring.datasource.password", () -> "postgres");
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
    }

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    protected MvcResult performGet(String path, String token) throws Exception {
        var req = get(path).accept(MediaType.APPLICATION_JSON);
        if (token != null && !token.isBlank()) {
            req.header("Authorization", "Bearer " + token);
        }
        return mockMvc.perform(req).andReturn();
    }

    protected MvcResult performPost(String path, Object body, String token) throws Exception {
        var req = post(path)
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .content(toJson(body));
        if (token != null && !token.isBlank()) {
            req.header("Authorization", "Bearer " + token);
        }
        return mockMvc.perform(req).andReturn();
    }

    protected MvcResult performPut(String path, Object body, String token) throws Exception {
        var req = put(path)
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .content(toJson(body));
        if (token != null && !token.isBlank()) {
            req.header("Authorization", "Bearer " + token);
        }
        return mockMvc.perform(req).andReturn();
    }

    protected MvcResult performDelete(String path, String token) throws Exception {
        var req = delete(path).accept(MediaType.APPLICATION_JSON);
        if (token != null && !token.isBlank()) {
            req.header("Authorization", "Bearer " + token);
        }
        return mockMvc.perform(req).andReturn();
    }

    protected void assertHttpStatus(MvcResult result, int expected) throws Exception {
        assertThat(result.getResponse().getStatus()).isEqualTo(expected);
    }

    protected void assertRCode(MvcResult result, int expectedCode) throws Exception {
        JsonNode node = readJson(result);
        assertThat(node.path("code").asInt()).isEqualTo(expectedCode);
    }

    protected JsonNode readJson(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    protected String toJson(Object body) {
        try {
            return objectMapper.writeValueAsString(body);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Failed to serialize request body", e);
        }
    }
}
