package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.WebhookConfigDTO;
import com.ljwx.platform.app.dto.WebhookConfigQueryDTO;
import com.ljwx.platform.app.dto.WebhookLogQueryDTO;
import com.ljwx.platform.app.service.WebhookService;
import com.ljwx.platform.app.vo.WebhookConfigVO;
import com.ljwx.platform.app.vo.WebhookLogVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Webhook Controller
 *
 * @author LJWX Platform
 * @since Phase 49
 */
@RestController
@RequestMapping("/api/v1/webhooks")
@RequiredArgsConstructor
public class WebhookController {

    private final WebhookService webhookService;

    /**
     * Create webhook config
     *
     * @param dto webhook config DTO
     * @return webhook config ID
     */
    @PreAuthorize("hasAuthority('system:webhook:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody WebhookConfigDTO dto) {
        Long id = webhookService.createWebhookConfig(dto);
        return Result.ok(id);
    }

    /**
     * Update webhook config
     *
     * @param id webhook config ID
     * @param dto webhook config DTO
     * @return success
     */
    @PreAuthorize("hasAuthority('system:webhook:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody WebhookConfigDTO dto) {
        webhookService.updateWebhookConfig(id, dto);
        return Result.ok();
    }

    /**
     * Delete webhook config
     *
     * @param id webhook config ID
     * @return success
     */
    @PreAuthorize("hasAuthority('system:webhook:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        webhookService.deleteWebhookConfig(id);
        return Result.ok();
    }

    /**
     * Get webhook config by ID
     *
     * @param id webhook config ID
     * @return webhook config VO
     */
    @PreAuthorize("hasAuthority('system:webhook:query')")
    @GetMapping("/{id}")
    public Result<WebhookConfigVO> getById(@PathVariable Long id) {
        WebhookConfigVO vo = webhookService.getWebhookConfigById(id);
        return Result.ok(vo);
    }

    /**
     * List webhook configs
     *
     * @param query query conditions
     * @return page result
     */
    @PreAuthorize("hasAuthority('system:webhook:list')")
    @GetMapping
    public Result<PageResult<WebhookConfigVO>> list(WebhookConfigQueryDTO query) {
        PageResult<WebhookConfigVO> result = webhookService.listWebhookConfigs(query);
        return Result.ok(result);
    }

    /**
     * List webhook logs
     *
     * @param id webhook config ID
     * @param query query conditions
     * @return page result
     */
    @PreAuthorize("hasAuthority('system:webhook:log:list')")
    @GetMapping("/{id}/logs")
    public Result<PageResult<WebhookLogVO>> listLogs(@PathVariable Long id, WebhookLogQueryDTO query) {
        query.setWebhookId(id);
        PageResult<WebhookLogVO> result = webhookService.listWebhookLogs(query);
        return Result.ok(result);
    }
}
