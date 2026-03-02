package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.OpenAppSecretDTO;
import com.ljwx.platform.app.service.OpenAppSecretService;
import com.ljwx.platform.app.vo.OpenAppSecretVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Open API Secret Controller
 *
 * @author LJWX Platform
 * @since Phase 48
 */
@RestController
@RequestMapping("/api/v1/open-api/apps/{appId}/secrets")
@RequiredArgsConstructor
public class OpenAppSecretController {

    private final OpenAppSecretService secretService;

    /**
     * Create new secret
     *
     * @param appId Application ID
     * @param dto   Secret DTO
     * @return Secret VO with plain text key
     */
    @PreAuthorize("hasAuthority('system:openApi:secret:add')")
    @PostMapping
    public Result<OpenAppSecretVO> createSecret(@PathVariable Long appId,
                                            @Valid @RequestBody OpenAppSecretDTO dto) {
        dto.setAppId(appId);
        OpenAppSecretVO vo = secretService.createSecret(dto);
        return Result.ok(vo);
    }

    /**
     * Rotate secret
     *
     * @param appId    Application ID
     * @param secretId Secret ID
     * @return New secret VO with plain text key
     */
    @PreAuthorize("hasAuthority('system:openApi:secret:edit')")
    @PutMapping("/{secretId}/rotate")
    public Result<OpenAppSecretVO> rotateSecret(@PathVariable Long appId,
                                            @PathVariable Long secretId) {
        OpenAppSecretVO vo = secretService.rotateSecret(appId, secretId);
        return Result.ok(vo);
    }

    /**
     * Delete secret
     *
     * @param appId    Application ID
     * @param secretId Secret ID
     * @return Success response
     */
    @PreAuthorize("hasAuthority('system:openApi:secret:delete')")
    @DeleteMapping("/{secretId}")
    public Result<Void> deleteSecret(@PathVariable Long appId,
                                 @PathVariable Long secretId) {
        secretService.deleteSecret(appId, secretId);
        return Result.ok();
    }

    /**
     * List secrets by app ID
     *
     * @param appId Application ID
     * @return Secret list (masked keys)
     */
    @PreAuthorize("hasAuthority('system:openApi:secret:list')")
    @GetMapping
    public Result<List<OpenAppSecretVO>> listSecrets(@PathVariable Long appId) {
        List<OpenAppSecretVO> list = secretService.listSecrets(appId);
        return Result.ok(list);
    }
}
