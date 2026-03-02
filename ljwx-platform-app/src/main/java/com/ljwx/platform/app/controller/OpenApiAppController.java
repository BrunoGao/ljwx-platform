package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.OpenApiAppService;
import com.ljwx.platform.app.domain.dto.OpenAppDTO;
import com.ljwx.platform.app.domain.dto.OpenAppQueryDTO;
import com.ljwx.platform.app.domain.vo.OpenAppVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Open API Application Controller
 *
 * @author LJWX Platform
 * @since Phase 47
 */
@RestController
@RequestMapping("/api/v1/open-api/apps")
@RequiredArgsConstructor
public class OpenApiAppController {

    private final OpenApiAppService openApiAppService;

    /**
     * Create new application
     *
     * @param dto application DTO
     * @return application VO with generated keys
     */
    @PreAuthorize("hasAuthority('system:openApi:app:add')")
    @PostMapping
    public Result<OpenAppVO> create(@Valid @RequestBody OpenAppDTO dto) {
        return Result.ok(openApiAppService.create(dto));
    }

    /**
     * Update application
     *
     * @param id application ID
     * @param dto application DTO
     * @return success result
     */
    @PreAuthorize("hasAuthority('system:openApi:app:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody OpenAppDTO dto) {
        openApiAppService.update(id, dto);
        return Result.ok();
    }

    /**
     * Delete application
     *
     * @param id application ID
     * @return success result
     */
    @PreAuthorize("hasAuthority('system:openApi:app:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        openApiAppService.delete(id);
        return Result.ok();
    }

    /**
     * Get application by ID
     *
     * @param id application ID
     * @return application VO
     */
    @PreAuthorize("hasAuthority('system:openApi:app:query')")
    @GetMapping("/{id}")
    public Result<OpenAppVO> getById(@PathVariable Long id) {
        return Result.ok(openApiAppService.getById(id));
    }

    /**
     * List applications with pagination
     *
     * @param query query DTO
     * @return page result
     */
    @PreAuthorize("hasAuthority('system:openApi:app:list')")
    @GetMapping
    public Result<PageResult<OpenAppVO>> list(OpenAppQueryDTO query) {
        return Result.ok(openApiAppService.list(query));
    }

    /**
     * Regenerate application secret
     *
     * @param id application ID
     * @return new secret
     */
    @PreAuthorize("hasAuthority('system:openApi:app:edit')")
    @PostMapping("/{id}/regenerate-secret")
    public Result<String> regenerateSecret(@PathVariable Long id) {
        return Result.ok(openApiAppService.regenerateSecret(id));
    }
}
