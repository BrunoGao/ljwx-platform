package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.ai.AiConfigUpdateDTO;
import com.ljwx.platform.app.service.AiConfigAppService;
import com.ljwx.platform.app.vo.ai.AiConfigVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * AI 配置控制器
 *
 * @author LJWX Platform
 */
@RestController
@RequestMapping("/api/v1/ai/config")
@RequiredArgsConstructor
public class AiConfigController {

    private final AiConfigAppService aiConfigAppService;

    /**
     * 查看配置（API Key 脱敏）
     *
     * @return AI 配置
     */
    @PreAuthorize("hasAuthority('system:ai:config:query')")
    @GetMapping
    public Result<AiConfigVO> getConfig() {
        return Result.ok(aiConfigAppService.getConfig());
    }

    /**
     * 更新配置（含 API Key 轮换）
     *
     * @param dto 更新 DTO
     * @return 成功响应
     */
    @PreAuthorize("hasAuthority('system:ai:config:edit')")
    @PutMapping
    public Result<Void> updateConfig(@Valid @RequestBody AiConfigUpdateDTO dto) {
        aiConfigAppService.updateConfig(dto);
        return Result.ok();
    }
}
